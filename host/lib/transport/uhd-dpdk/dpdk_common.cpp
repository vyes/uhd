//
// Copyright 2019 Ettus Research, a National Instruments brand
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

// CUDA runtime
//#include <cuda_runtime.h>

//DPDK GPU
#define ALLOW_EXPERIMENTAL_API
#include <rte_gpudev.h>

//NVIDIA GDRCopy
//#include <gdrapi.h>
#define GPU_PAGE_SHIFT 16
#define GPU_PAGE_SIZE (1UL << GPU_PAGE_SHIFT)
#define GPU_PAGE_OFFSET (GPU_PAGE_SIZE - 1)
#define GPU_PAGE_MASK (~GPU_PAGE_OFFSET)

#define CPU_PAGE_SIZE 4096

#include <uhd/utils/algorithm.hpp>
#include <uhd/utils/log.hpp>
#include <uhdlib/transport/dpdk/arp.hpp>
#include <uhdlib/transport/dpdk/common.hpp>
#include <uhdlib/transport/dpdk/udp.hpp>
#include <uhdlib/transport/dpdk_io_service.hpp>
#include <uhdlib/utils/prefs.hpp>
#include <arpa/inet.h>
#include <rte_arp.h>
#include <boost/algorithm/string.hpp>

#include "../../../../host/lib/usrp/x300/x300_fw_common.h" //X300_VITA_UDP_PORT

namespace uhd { namespace transport { namespace dpdk {

namespace {
constexpr uint64_t USEC                      = 1000000;
constexpr size_t DEFAULT_FRAME_SIZE          = 8000;
constexpr int DEFAULT_NUM_MBUFS              = 1024;
constexpr int DEFAULT_MBUF_CACHE_SIZE        = 315;
constexpr size_t DPDK_HEADERS_SIZE           = 14 + 20 + 8; // Ethernet + IPv4 + UDP
constexpr uint16_t DPDK_DEFAULT_RING_SIZE    = 512;
constexpr int DEFAULT_DPDK_LINK_INIT_TIMEOUT = 1000;
constexpr int LINK_STATUS_INTERVAL           = 250;

inline char* eal_add_opt(
    std::vector<const char*>& argv, size_t n, char* dst, const char* opt, const char* arg)
{
    UHD_LOG_TRACE("DPDK", opt << " " << arg);
    char* ptr = dst;
    strncpy(ptr, opt, n);
    argv.push_back(ptr);
    ptr += strlen(opt) + 1;
    n -= ptr - dst;
    strncpy(ptr, arg, n);
    argv.push_back(ptr);
    ptr += strlen(arg) + 1;
    return ptr;
}

inline void separate_rte_ipv4_addr(
    const std::string ipv4, uint32_t& rte_ipv4_addr, uint32_t& netmask)
{
    std::vector<std::string> result;
    boost::algorithm::split(
        result, ipv4, [](const char& in) { return in == '/'; }, boost::token_compress_on);
    UHD_ASSERT_THROW(result.size() == 2);
    rte_ipv4_addr   = (uint32_t)inet_addr(result[0].c_str());
    int netbits = std::atoi(result[1].c_str());
    netmask     = htonl(0xffffffff << (32 - netbits));
}
} // namespace

dpdk_port::uptr dpdk_port::make(port_id_t port,
    size_t mtu,
    uint16_t num_rx_queues,
    uint16_t num_tx_queues,
    uint16_t num_desc,
    struct rte_mempool* cpu_rx_pktbuf_pool,
    struct rte_mempool* cpu_tx_pktbuf_pool,
    struct rte_mempool* gpu_rx_pktbuf_pool,
    struct rte_mempool* gpu_tx_pktbuf_pool,
    std::string rte_ipv4_address)
{
    return std::make_unique<dpdk_port>(
        port, mtu, num_rx_queues, num_tx_queues, num_desc, cpu_rx_pktbuf_pool, cpu_tx_pktbuf_pool, gpu_rx_pktbuf_pool, gpu_tx_pktbuf_pool, rte_ipv4_address);
}

dpdk_port::dpdk_port(port_id_t port,
    size_t mtu,
    uint16_t num_rx_queues,
    uint16_t num_tx_queues,
    uint16_t num_desc,
    struct rte_mempool* cpu_rx_pktbuf_pool,
    struct rte_mempool* cpu_tx_pktbuf_pool,
    struct rte_mempool* gpu_rx_pktbuf_pool,
    struct rte_mempool* gpu_tx_pktbuf_pool, //unused there!
    std::string rte_ipv4_address)
    : _port(port)
    , _mtu(mtu)
    //, _num_rx_queues(num_rx_queues)
    //, _num_tx_queues(num_tx_queues)
    , _cpu_rx_pktbuf_pool(cpu_rx_pktbuf_pool)
    , _cpu_tx_pktbuf_pool(cpu_tx_pktbuf_pool)
    , _gpu_rx_pktbuf_pool(gpu_rx_pktbuf_pool)
    , _gpu_tx_pktbuf_pool(gpu_tx_pktbuf_pool)
{
    int retval;

    separate_rte_ipv4_addr(rte_ipv4_address, _ipv4, _netmask);

    /* Set hardware offloads */
    struct rte_eth_dev_info dev_info;
    rte_eth_dev_info_get(_port, &dev_info);

/*
    uint32_t eth_overhead;
    if (dev_info.max_mtu != UINT16_MAX && dev_info.max_rx_pktlen > dev_info.max_mtu) {
		eth_overhead = dev_info.max_rx_pktlen - dev_info.max_mtu;
    } else {
		eth_overhead = RTE_ETHER_HDR_LEN + RTE_ETHER_CRC_LEN;
    }
    UHD_LOGGER_INFO("DPDK") << boost::format("dev_info.max_mtu=%d dev_info.max_rx_pktlen=%d eth_overhead=%d")
                                        % dev_info.max_mtu % dev_info.max_rx_pktlen % eth_overhead;
*/

    // Check number of available RX queues
    if (dev_info.max_rx_queues < num_rx_queues) {
        _num_rx_queues = dev_info.max_rx_queues;
        UHD_LOGGER_WARNING("DPDK")
            << boost::format("%d: Maximum RX queues supported is %d") % _port % _num_rx_queues;
    } else {
        _num_rx_queues = num_rx_queues;
    }

    //last queue to GPU if enabled!
    if (_gpu_rx_pktbuf_pool != NULL) {
        if (dev_info.max_rx_queues == 1) {
            UHD_LOG_ERROR("DPDK", "NIC has only one RX queue");
            throw uhd::runtime_error("DPDK: NIC has only one RX queue");
        }
        _num_rx_queues += 1;
    }

    // Check number of available TX queues
    if (dev_info.max_tx_queues < num_tx_queues) {
        _num_tx_queues = dev_info.max_tx_queues;
        UHD_LOGGER_WARNING("DPDK")
            << boost::format("%d: Maximum TX queues supported is %d") % _port % _num_tx_queues;
    } else {
        _num_tx_queues = num_tx_queues;
    }

    UHD_LOGGER_INFO("DPDK") << "NIC (" << _port << ") _num_rx_queues=" << _num_rx_queues << " _num_tx_queues=" << _num_tx_queues;

    struct rte_eth_conf port_conf   = {};
    #ifdef DEV_RX_OFFLOAD_JUMBO_FRAME
        port_conf.rxmode.offloads       = RTE_ETH_RX_OFFLOAD_IPV4_CKSUM | DEV_RX_OFFLOAD_JUMBO_FRAME;
    #else
        port_conf.rxmode.offloads       = RTE_ETH_RX_OFFLOAD_IPV4_CKSUM;
    #endif
    #if RTE_VER_YEAR > 21 || (RTE_VER_YEAR == 21 && RTE_VER_MONTH == 11)
//        port_conf.rxmode.mtu            = _mtu - eth_overhead;
        port_conf.rxmode.mtu            = _mtu;
    #else
        port_conf.rxmode.max_rx_pkt_len = _mtu;
    #endif
    port_conf.txmode.offloads       = RTE_ETH_TX_OFFLOAD_IPV4_CKSUM;
    port_conf.intr_conf.lsc         = 1; //???

    if (_gpu_rx_pktbuf_pool != NULL) {
        port_conf.rxmode.offloads |= RTE_ETH_RX_OFFLOAD_SCATTER | RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT;
    }

    //print RX offloads
    {
        uint64_t offloads = port_conf.rxmode.offloads;

        printf("NIC (%d) RX Offloads:", _port);
        if (offloads != 0) {
            uint64_t single_offload;
            int begin;
            int end;
            int bit;

            begin = __builtin_ctzll(offloads);
            end = sizeof(offloads) * CHAR_BIT - __builtin_clzll(offloads);

            single_offload = 1ULL << begin;
            for (bit = begin; bit < end; bit++) {
                if (offloads & single_offload) {
                    printf(" %s", rte_eth_dev_rx_offload_name(single_offload));
                }
                single_offload <<= 1;
            }
        }
        printf("\n");
    }

    if (_gpu_tx_pktbuf_pool != NULL) {
        port_conf.txmode.offloads |= RTE_ETH_TX_OFFLOAD_MULTI_SEGS;
    }

    //print TX offloads
    {
        uint64_t offloads = port_conf.txmode.offloads;

        printf("NIC (%d) TX Offloads:", _port);
        if (offloads != 0) {
            uint64_t single_offload;
            int begin;
            int end;
            int bit;

            begin = __builtin_ctzll(offloads);
            end = sizeof(offloads) * CHAR_BIT - __builtin_clzll(offloads);

            single_offload = 1ULL << begin;
            for (bit = begin; bit < end; bit++) {
                if (offloads & single_offload) {
                    printf(" %s", rte_eth_dev_tx_offload_name(single_offload));
                }
                single_offload <<= 1;
            }
        }
        printf("\n");
    }

    if ((dev_info.rx_offload_capa & port_conf.rxmode.offloads) != port_conf.rxmode.offloads) {
        UHD_LOGGER_ERROR("DPDK") << boost::format("%d: Only supports RX offloads 0x%0llx")
                                        % _port % dev_info.rx_offload_capa;
        throw uhd::runtime_error("DPDK: Missing required RX offloads");
    }
    if ((dev_info.tx_offload_capa & port_conf.txmode.offloads) != port_conf.txmode.offloads) {
        UHD_LOGGER_ERROR("DPDK") << boost::format("%d: Only supports TX offloads 0x%0llx")
                                        % _port % dev_info.tx_offload_capa;
        throw uhd::runtime_error("DPDK: Missing required TX offloads");
    }

    retval = rte_eth_dev_configure(_port, _num_rx_queues, _num_tx_queues, &port_conf);
    if (retval != 0) {
        UHD_LOG_ERROR("DPDK", "Failed to configure the device");
        throw uhd::runtime_error("DPDK: Failed to configure the device");
    }

    /* Set MTU and IPv4 address */
    retval = rte_eth_dev_set_mtu(_port, _mtu);
    if (retval) {
        uint16_t actual_mtu;
        UHD_LOGGER_WARNING("DPDK")
            << boost::format("Port %d: Could not set mtu to %d") % _port % _mtu;
        rte_eth_dev_get_mtu(_port, &actual_mtu);
        UHD_LOGGER_WARNING("DPDK")
            << boost::format("Port %d: Current mtu=%d") % _port % actual_mtu;
        _mtu = actual_mtu;
    }

    /* Set descriptor ring sizes */
    uint16_t rx_desc = num_desc;
    if (dev_info.rx_desc_lim.nb_max < rx_desc || dev_info.rx_desc_lim.nb_min > rx_desc
        || (dev_info.rx_desc_lim.nb_align - 1) & rx_desc) {
        UHD_LOGGER_ERROR("DPDK")
            << boost::format("%d: %d RX descriptors requested, but must be in [%d,%d]")
                   % _port % num_desc % dev_info.rx_desc_lim.nb_min
                   % dev_info.rx_desc_lim.nb_max;
        UHD_LOGGER_ERROR("DPDK")
            << boost::format("Num RX descriptors must also be aligned to 0x%x")
                   % dev_info.rx_desc_lim.nb_align;
        throw uhd::runtime_error("DPDK: Failed to allocate RX descriptors");
    }

    uint16_t tx_desc = num_desc;
    if (dev_info.tx_desc_lim.nb_max < tx_desc || dev_info.tx_desc_lim.nb_min > tx_desc
        || (dev_info.tx_desc_lim.nb_align - 1) & tx_desc) {
        UHD_LOGGER_ERROR("DPDK")
            << boost::format("%d: %d TX descriptors requested, but must be in [%d,%d]")
                   % _port % num_desc % dev_info.tx_desc_lim.nb_min
                   % dev_info.tx_desc_lim.nb_max;
        UHD_LOGGER_ERROR("DPDK")
            << boost::format("Num TX descriptors must also be aligned to 0x%x")
                   % dev_info.tx_desc_lim.nb_align;
        throw uhd::runtime_error("DPDK: Failed to allocate TX descriptors");
    }

    retval = rte_eth_dev_adjust_nb_rx_tx_desc(_port, &rx_desc, &tx_desc);
    if (retval != 0) {
        UHD_LOG_ERROR("DPDK", "Failed to configure the DMA queues ");
        throw uhd::runtime_error("DPDK: Failed to configure the DMA queues");
    }

    /* Set up the RX and TX DMA queues (May not be generally supported after
     * eth_dev_start) */
    unsigned int cpu_socket = rte_eth_dev_socket_id(_port);

    if (_gpu_rx_pktbuf_pool != NULL) {
        //setup GPU queue
        uint16_t gpu_queue = _num_rx_queues-1;

        //buffer split
        struct rte_eth_rxconf rxconf_qsplit;
        struct rte_eth_rxseg_split *rx_seg;
        union rte_eth_rxseg rx_useg[2] = {}; //CHDR header + payload

        memcpy(&rxconf_qsplit, &dev_info.default_rxconf, sizeof(rxconf_qsplit));

        rxconf_qsplit.offloads = RTE_ETH_RX_OFFLOAD_SCATTER | RTE_ETH_RX_OFFLOAD_BUFFER_SPLIT;
        rxconf_qsplit.rx_nseg = 2; //CHDR header + payload
        rxconf_qsplit.rx_seg = rx_useg;

        rx_seg = &rx_useg[0].split;
        rx_seg->mp = _cpu_rx_pktbuf_pool; //<- CHDR header
        //rx_seg->length = RTE_ETHER_HDR_LEN + 16; //RTE_ETHER_HDR_LEN + uint64_t CHDR header + uint64_t timestamp
        rx_seg->length = sizeof(struct rte_ether_hdr) + sizeof(struct rte_ipv4_hdr) + sizeof(struct rte_udp_hdr) + 16; //RTE_ETHER_HDR_LEN + uint64_t CHDR header + uint64_t timestamp
        rx_seg->offset = 0;

        rx_seg = &rx_useg[1].split;
        rx_seg->mp = _gpu_rx_pktbuf_pool; //<- payload
        rx_seg->length = 0;
        rx_seg->offset = 0; //???

        retval = rte_eth_rx_queue_setup(_port, gpu_queue, rx_desc, cpu_socket, &rxconf_qsplit, NULL);
        if (retval < 0) {
            UHD_LOGGER_ERROR("DPDK")
                << boost::format("Port %d: Could not init GPU RX queue %d") % _port % gpu_queue;
            throw uhd::runtime_error("DPDK: Failure to init GPU RX queue");
        }
    }

    for (uint16_t i = 0; i < _num_rx_queues - (_gpu_rx_pktbuf_pool != NULL ? 1 : 0); i++) {
        //setup CPU queues (note: last queue to GPU if enabled)
        retval = rte_eth_rx_queue_setup(_port, i, rx_desc, cpu_socket, NULL, _cpu_rx_pktbuf_pool);
        
        if (retval < 0) {
            UHD_LOGGER_ERROR("DPDK")
                << boost::format("Port %d: Could not init RX queue %d") % _port % i;
            throw uhd::runtime_error("DPDK: Failure to init RX queue");
        }
    }

    for (uint16_t i = 0; i < _num_tx_queues; i++) {
        struct rte_eth_txconf txconf = dev_info.default_txconf;
        txconf.offloads              = RTE_ETH_TX_OFFLOAD_IPV4_CKSUM;
        retval = rte_eth_tx_queue_setup(_port, i, tx_desc, cpu_socket, &txconf);
        if (retval < 0) {
            UHD_LOGGER_ERROR("DPDK")
                << boost::format("Port %d: Could not init TX queue %d") % _port % i;
            throw uhd::runtime_error("DPDK: Failure to init TX queue");
        }
    }

    /* TODO: Enable multiple queues (only support 1 right now) */

    /* Start the Ethernet device */
    retval = rte_eth_dev_start(_port);
    if (retval < 0) {
        UHD_LOGGER_ERROR("DPDK")
            << boost::format("Port %d: Could not start device") % _port;
        throw uhd::runtime_error("DPDK: Failure to start device");
    }

#if 0 //flow dissect by UDP and RAW items... currently, Mellanox Connectx-5 does not support this!
    if (_gpu_rx_pktbuf_pool != NULL) {
        //last queue to GPU with DPDK flow api
        uint16_t gpu_queue = _num_rx_queues-1;
        /* 
            https://community.mellanox.com/s/question/0D51T00006aYXHzSAO/dpdk-rteflow-is-degrading-performance-when-testing-on-connect-x5-100g-en-100g

            DEV_TX_OFFLOAD_VLAN_INSERT
            DEV_TX_OFFLOAD_TCP_TSO
        */

        //X300_VITA_UDP_PORT 49153 -> GPU
        
        //flow attr ingress
        struct rte_flow_attr attr;
        memset(&attr, 0, sizeof(attr));
        attr.ingress = 1;

        //flow action
        struct rte_flow_action action[2];
        memset(action, 0, sizeof(action));
        action[0].type = RTE_FLOW_ACTION_TYPE_QUEUE;
        struct rte_flow_action_queue queue;
        queue.index = gpu_queue; //last is GPU queue!
        //queue.index = 0; //to CPU!!!
        action[0].conf = &queue;
        action[1].type = RTE_FLOW_ACTION_TYPE_END;

        //flow pattern (UDP source port is X300_VITA_UDP_PORT)
        //struct rte_flow_item pattern[1 /*ETH*/ + 1 /*IPv4*/ + 1 /*UDP*/ + 1 /*CHDR (RAW)*/ + 1 /*END*/]; //Mellanox currently does not support RTE_FLOW_ITEM_TYPE_RAW
        struct rte_flow_item pattern[1 /*ETH*/ + 1 /*IPv4*/ + 1 /*UDP*/ + 1 /*END*/];
        memset(pattern, 0, sizeof(pattern));
        
        pattern[0].type = RTE_FLOW_ITEM_TYPE_ETH;
        
        pattern[1].type = RTE_FLOW_ITEM_TYPE_IPV4;
        struct rte_flow_item_ipv4 ip4_spec;
        memset(&ip4_spec, 0, sizeof(ip4_spec));
        ip4_spec.hdr.next_proto_id = IPPROTO_UDP;
        //ip4_spec.hdr.total_length = RTE_BE16(8044);
        struct rte_flow_item_ipv4 ip4_mask;
        pattern[1].spec = &ip4_spec;
        memset(&ip4_mask, 0, sizeof(ip4_mask));
        ip4_mask.hdr.next_proto_id = 0xff;
        //ip4_mask.hdr.total_length = RTE_BE16(0xffff);
        pattern[1].mask = &ip4_mask;
        
        //Mellanox currently does not support RTE_FLOW_ITEM_TYPE_RAW... try to use the dgram_len value from UDP header to determine DATA CHDR packet? Ops... Mellanox currently does not support this! rte_flow_error: mask enables non supported bits
        pattern[2].type = RTE_FLOW_ITEM_TYPE_UDP;
        static struct rte_flow_item_udp udp_spec;
        memset(&udp_spec, 0, sizeof(udp_spec));
        udp_spec.hdr.src_port = RTE_BE16(X300_VITA_UDP_PORT);
        udp_spec.hdr.dst_port = RTE_BE16(65533); //DPDK uses ports 65533 DATA, 65534 CONTROL, 65535 DISCOVERY
        //udp_spec.hdr.dgram_len = RTE_BE16(8016 + 8 /*CHDR header*/); //use SPP!!! //Mellanox currently does not support this! 8( rte_flow_error: mask enables non supported bits
        pattern[2].spec = &udp_spec;
        static struct rte_flow_item_udp udp_mask;
        memset(&udp_mask, 0, sizeof(udp_mask));
        udp_mask.hdr.src_port = RTE_BE16(0xffff);
        udp_mask.hdr.dst_port = RTE_BE16(0xffff);
        //udp_mask.hdr.dgram_len = RTE_BE16(0xffff); //Mellanox currently does not support this! 8( rte_flow_error: mask enables non supported bits
        pattern[2].mask = &udp_mask;

        /*
        //Mellanox currently does not support RTE_FLOW_ITEM_TYPE_RAW items 8(
        pattern[3].type = RTE_FLOW_ITEM_TYPE_RAW;
        static struct rte_flow_item_raw raw_spec;
        memset(&raw_spec, 0, sizeof(raw_spec));
        raw_spec.relative = 1;
        raw_spec.offset = 6;
        raw_spec.length = 1;
        const uint8_t raw_spec_pattern = 0xe0; //Data with Timestamp
        raw_spec.pattern = &raw_spec_pattern;
        pattern[3].spec = &raw_spec;
        //static struct rte_flow_item_raw raw_mask;
        //memset(&raw_mask, 0, sizeof(raw_mask));
        //raw_mask.offset = 6;
        //raw_mask.length = 1;
        //const uint8_t raw_mask_pattern = 0xff;
        //raw_mask.pattern = &raw_mask_pattern;
        //pattern[3].mask = &raw_mask;

        pattern[4].type = RTE_FLOW_ITEM_TYPE_END;
        */
        pattern[3].type = RTE_FLOW_ITEM_TYPE_END;

        struct rte_flow *flow = NULL;
        struct rte_flow_error flow_error;
        retval = rte_flow_validate(_port, &attr, pattern, action, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to validate flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to validate flow");
        }
        flow = rte_flow_create(_port, &attr, pattern, action, &flow_error);
        if (flow == NULL) {
            UHD_LOG_ERROR("DPDK", "Failed to create flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to create flow");
        }
    }
#endif

#if 0 //flow dissect by FLEX item... currently, Mellanox Connectx-5 does not support this!
    if (_gpu_rx_pktbuf_pool != NULL) {
        //last queue to GPU with DPDK flow api
        uint16_t gpu_queue = _num_rx_queues-1;
        /* 
            https://community.mellanox.com/s/question/0D51T00006aYXHzSAO/dpdk-rteflow-is-degrading-performance-when-testing-on-connect-x5-100g-en-100g

            DEV_TX_OFFLOAD_VLAN_INSERT
            DEV_TX_OFFLOAD_TCP_TSO
        */

        //X300_VITA_UDP_PORT 49153 -> GPU


        //flex item
        /*
            The form of a CVITA packet is the following:

            Address (Bytes) Length (Bytes)  Payload
            0               8               Compressed Header (CHDR)
            8               8               Fractional Time (Optional!)
            8/16            -               Data

            The 64 Bits in the compressed header have the following meaning:

            Bits	Meaning
            63:62	Packet Type
            61	    Has fractional time stamp (1: Yes)
            60	    End-of-burst or error flag
            59:48	12-bit sequence number
            47:32	Total packet length in Bytes
            31:0	Stream ID (SID)

            Bit 63	Bit 62	Bit 60	Packet Type
            0	    0	    0	    Data
            0	    0	    1	    Data (End-of-burst)
            0	    1	    0	    Flow Control
            1	    0	    0	    Command Packet
            1	    1	    0	    Command Response
            1	    1	    1	    Command Response (Error)
        */
        struct rte_flow_item_flex_conf flex_conf;
        memset(&flex_conf, 0, sizeof(flex_conf));
        /* single CHDR header in a packet. Can be ether inner or outer */
        flex_conf.tunnel = FLEX_TUNNEL_MODE_SINGLE,
        flex_conf.next_header.field_mode = FIELD_MODE_FIXED;  /* fixed-size header */
        flex_conf.next_header.field_size = 64; // CHDR header size (bits)
        
        /* CHDR header is followed by a payload */
        //flex_conf.next_protocol = {};
        /* single sample that covers entire CHDR header */
            struct rte_flow_item_flex_field sample_data;
            memset(&sample_data, 0, sizeof(sample_data));
            sample_data.field_mode = FIELD_MODE_FIXED;
            sample_data.field_size = 64; // CHDR header size (bits)
            sample_data.field_base = 0;
        flex_conf.sample_data = &sample_data;
        flex_conf.nb_samples = 1;
        /* CHDR protocol follows UDP header */
                struct rte_flow_item_udp udp_spec;
                memset(&udp_spec, 0, sizeof(udp_spec));
                udp_spec.hdr.src_port = RTE_BE16(X300_VITA_UDP_PORT);
                udp_spec.hdr.dst_port = RTE_BE16(65533); //DPDK uses ports 65533 DATA, 65534 CONTROL, 65535 DISCOVERY
                struct rte_flow_item_udp udp_mask;
                memset(&udp_mask, 0, sizeof(udp_mask));
                udp_mask.hdr.src_port = RTE_BE16(0xffff);
                udp_mask.hdr.dst_port = RTE_BE16(0xffff);
            struct rte_flow_item_flex_link input_link;
            memset(&input_link, 0, sizeof(input_link));
            input_link.item.type = RTE_FLOW_ITEM_TYPE_UDP;
            input_link.item.spec = &udp_spec;
            input_link.item.mask = &udp_mask;
        flex_conf.input_link = &input_link;
        flex_conf.nb_inputs = 1;
        /* no network protocol follows CHDR header */
        //flex_conf.nb_outputs = 0;
        
        struct rte_flow_error flow_error;
        struct rte_flow_item_flex_handle *flex_handle;
        flex_handle = rte_flow_flex_item_create(_port, &flex_conf, &flow_error);
        if (flex_handle == NULL) {
            UHD_LOG_ERROR("DPDK", "Failed to create flex item (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to create flex item");
        }

        //flow attr ingress
        struct rte_flow_attr attr;
        memset(&attr, 0, sizeof(attr));
        attr.ingress = 1;

        //flow action
        struct rte_flow_action action[2];
        memset(action, 0, sizeof(action));
        action[0].type = RTE_FLOW_ACTION_TYPE_QUEUE;
        struct rte_flow_action_queue queue;
        queue.index = gpu_queue; //last is GPU queue!
        //queue.index = 0; //to CPU!!!
        action[0].conf = &queue;
        action[1].type = RTE_FLOW_ACTION_TYPE_END;

        //flow pattern
        struct rte_flow_item pattern[1 /*FLEX*/ + 1 /*END*/];
        memset(pattern, 0, sizeof(pattern));
        pattern[0].type = RTE_FLOW_ITEM_TYPE_FLEX;
                const uint8_t spec_pattern[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x00};
            struct rte_flow_item_flex flex_spec = {
                .handle = flex_handle,
                .length = sizeof(uint64_t), // CHDR header size (bytes)
                .pattern = &spec_pattern[0],
            };
        pattern[0].spec = &flex_spec;
                        const uint8_t spec_mask[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x00};
            struct rte_flow_item_flex flex_mask = {
                .handle = flex_handle,
                .length = sizeof(uint64_t), // CHDR header size (bytes)
                .pattern = &spec_mask[0],
            };
        pattern[0].mask = &flex_mask;
        pattern[1].type = RTE_FLOW_ITEM_TYPE_END;

        struct rte_flow *flow = NULL;
        retval = rte_flow_validate(_port, &attr, pattern, action, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to validate flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to validate flow");
        }
        flow = rte_flow_create(_port, &attr, pattern, action, &flow_error);
        if (flow == NULL) {
            UHD_LOG_ERROR("DPDK", "Failed to create flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to create flow");
        }
    }
#endif

    if (_gpu_rx_pktbuf_pool != NULL) {
        //last queue to GPU with DPDK flow API after stream setup done... for now enqueue all traffic to CPU queue 0
        
        //flow attr ingress
        struct rte_flow_attr attr;
        memset(&attr, 0, sizeof(attr));
        attr.ingress = 1;

        //flow action
        struct rte_flow_action action[2];
        memset(action, 0, sizeof(action));
        action[0].type = RTE_FLOW_ACTION_TYPE_QUEUE;
        struct rte_flow_action_queue queue;
        queue.index = 0; //last is GPU queue!
        action[0].conf = &queue;
        action[1].type = RTE_FLOW_ACTION_TYPE_END;

        //flow pattern (empty)
        struct rte_flow_item pattern[1 /*END*/];
        memset(pattern, 0, sizeof(pattern));
        
        pattern[0].type = RTE_FLOW_ITEM_TYPE_END;
        
        struct rte_flow_error flow_error;
        retval = rte_flow_validate(_port, &attr, pattern, action, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to validate flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to validate flow");
        }
        _flow = rte_flow_create(_port, &attr, pattern, action, &flow_error);
        if (_flow == NULL) {
            UHD_LOG_ERROR("DPDK", "Failed to create flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to create flow");
        }

        UHD_LOG_TRACE("DPDK", "Flow to CPU created");
    }

    /* Grab and display the port MAC address. */
    rte_eth_macaddr_get(_port, &_mac_addr);
    UHD_LOGGER_TRACE("DPDK") << "Port " << _port
                             << " MAC: " << eth_addr_to_string(_mac_addr);
}

dpdk_port::~dpdk_port()
{
    rte_eth_dev_stop(_port);
    rte_spinlock_lock(&_spinlock);
    for (auto kv : _arp_table) {
        for (auto req : kv.second->reqs) {
            req->cond.notify_one();
        }
        rte_free(kv.second);
    }
    _arp_table.clear();
    rte_spinlock_unlock(&_spinlock);
}

uint16_t dpdk_port::alloc_udp_port(uint16_t udp_port)
{
    uint16_t port_selected;
    std::lock_guard<std::mutex> lock(_mutex);
    if (udp_port) {
        if (_udp_ports.count(rte_be_to_cpu_16(udp_port))) {
            return 0;
        }
        port_selected = rte_be_to_cpu_16(udp_port);
    } else {
        if (_udp_ports.size() >= 65535) {
            UHD_LOG_WARNING("DPDK", "Attempted to allocate UDP port, but none remain");
            return 0;
        }
        port_selected = _next_udp_port;
        while (true) {
            if (port_selected == 0) {
                continue;
            }
            if (_udp_ports.count(port_selected) == 0) {
                _next_udp_port = port_selected - 1;
                break;
            }
            if (port_selected - 1 == _next_udp_port) {
                return 0;
            }
            port_selected--;
        }
    }
    _udp_ports.insert(port_selected);
    return rte_cpu_to_be_16(port_selected);
}

int dpdk_port::_arp_reply(queue_id_t queue_id, struct rte_arp_hdr* arp_req)
{
    struct rte_mbuf* mbuf;
    struct rte_ether_hdr* hdr;
    struct rte_arp_hdr* arp_frame;

    mbuf = rte_pktmbuf_alloc(_cpu_tx_pktbuf_pool);
    if (unlikely(mbuf == NULL)) {
        UHD_LOG_WARNING("DPDK", "Could not allocate packet buffer for ARP response");
        return -ENOMEM;
    }

    hdr       = rte_pktmbuf_mtod(mbuf, struct rte_ether_hdr*);
    arp_frame = (struct rte_arp_hdr*)&hdr[1];

    #if RTE_VER_YEAR > 21 || (RTE_VER_YEAR == 21 && RTE_VER_MONTH == 11)
        rte_ether_addr_copy(&arp_req->arp_data.arp_sha, &hdr->dst_addr);
        rte_ether_addr_copy(&_mac_addr, &hdr->src_addr);
    #else
        rte_ether_addr_copy(&arp_req->arp_data.arp_sha, &hdr->d_addr);
        rte_ether_addr_copy(&_mac_addr, &hdr->s_addr);
    #endif
    hdr->ether_type = rte_cpu_to_be_16(RTE_ETHER_TYPE_ARP);

    arp_frame->arp_hardware = rte_cpu_to_be_16(RTE_ARP_HRD_ETHER);
    arp_frame->arp_protocol = rte_cpu_to_be_16(RTE_ETHER_TYPE_IPV4);
    arp_frame->arp_hlen = 6;
    arp_frame->arp_plen = 4;
    arp_frame->arp_opcode  = rte_cpu_to_be_16(RTE_ARP_OP_REPLY);
    rte_ether_addr_copy(&_mac_addr, &arp_frame->arp_data.arp_sha);
    arp_frame->arp_data.arp_sip = _ipv4;
    #if RTE_VER_YEAR > 21 || (RTE_VER_YEAR == 21 && RTE_VER_MONTH == 11)
        rte_ether_addr_copy(&hdr->dst_addr, &arp_frame->arp_data.arp_tha);
    #else
        rte_ether_addr_copy(&hdr->d_addr, &arp_frame->arp_data.arp_tha);
    #endif
    arp_frame->arp_data.arp_tip = arp_req->arp_data.arp_sip;

    mbuf->pkt_len  = 42;
    mbuf->data_len = 42;

    if (rte_eth_tx_burst(_port, queue_id, &mbuf, 1) != 1) {
        UHD_LOGGER_WARNING("DPDK")
            << boost::format("%s: TX descriptor ring is full") % __func__;
        rte_pktmbuf_free(mbuf);
        return -EAGAIN;
    }
    return 0;
}

static dpdk_ctx::sptr global_ctx = nullptr;
static std::mutex global_ctx_mutex;

dpdk_ctx::sptr dpdk_ctx::get()
{
    std::lock_guard<std::mutex> lock(global_ctx_mutex);
    if (!global_ctx) {
        global_ctx = std::make_shared<dpdk_ctx>();
    }
    return global_ctx;
}

dpdk_ctx::dpdk_ctx(void) : _init_done(false) {}

dpdk_ctx::~dpdk_ctx(void)
{
    std::lock_guard<std::mutex> lock(global_ctx_mutex);
    global_ctx = nullptr;
    // Destroy the io service
    _io_srv_portid_map.clear();
    // Destroy and stop all the ports
    _ports.clear();
    // Free mempools
    for (auto& pool : _cpu_rx_pktbuf_pools) {
        rte_mempool_free(pool);
    }
    for (auto& pool : _cpu_tx_pktbuf_pools) {
        rte_mempool_free(pool);
    }
    for (auto& pool : _gpu_rx_pktbuf_pools) {
        rte_mempool_free(pool);
    }
    for (auto& pool : _gpu_tx_pktbuf_pools) {
        rte_mempool_free(pool);
    }
    // Free EAL resources
    rte_eal_cleanup();
}

void dpdk_ctx::_eal_init(const device_addr_t& eal_args)
{
    /* Build up argc and argv */
    std::vector<const char*> argv;
    argv.push_back("uhd::transport::dpdk");
    auto args = new std::array<char, 4096>();
    char* opt = args->data();
    char* end = args->data() + args->size();
    UHD_LOG_TRACE("DPDK", "EAL init options: ");
    for (std::string& key : eal_args.keys()) {
        std::string val = eal_args[key];
        if (key == "dpdk_coremask") {
            opt = eal_add_opt(argv, end - opt, opt, "-c", val.c_str());
        } else if (key == "dpdk_corelist") {
            /* NOTE: This arg may have commas, so limited to config file */
            opt = eal_add_opt(argv, end - opt, opt, "-l", val.c_str());
        } else if (key == "dpdk_coremap") {
            opt = eal_add_opt(argv, end - opt, opt, "--lcores", val.c_str());
        } else if (key == "dpdk_master_lcore") {
            opt = eal_add_opt(argv, end - opt, opt, "--master-lcore", val.c_str());
        } else if (key == "dpdk_pci_blacklist") {
            opt = eal_add_opt(argv, end - opt, opt, "-b", val.c_str());
        } else if (key == "dpdk_pci_whitelist") {
            //allow miltiple devices in whitelist with syntax dpdk_pci_whitelist=<dev1>|<dev2>[,dev_args]|<dev3>
            std::vector<std::string> devs;
            boost::split(devs, val, [](char c){return c == '|';});
            for (std::string& dev : devs) {
                opt = eal_add_opt(argv, end - opt, opt, "-a", dev.c_str());
            }
        } else if (key == "dpdk_log_level") {
            opt = eal_add_opt(argv, end - opt, opt, "--log-level", val.c_str());
        } else if (key == "dpdk_huge_dir") {
            opt = eal_add_opt(argv, end - opt, opt, "--huge-dir", val.c_str());
        } else if (key == "dpdk_file_prefix") {
            opt = eal_add_opt(argv, end - opt, opt, "--file-prefix", val.c_str());
        } else if (key == "dpdk_driver") {
            opt = eal_add_opt(argv, end - opt, opt, "-d", val.c_str());
        }
        /* TODO: Change where log goes?
           int rte_openlog_stream( FILE * f)
         */
    }
    /* Init DPDK's EAL */
    int ret = rte_eal_init(argv.size(), (char**)argv.data());
    /* Done with the temporaries */
    delete args;

    if (ret < 0) {
        UHD_LOG_ERROR("DPDK", "Error with EAL initialization");
        throw uhd::runtime_error("Error with EAL initialization");
    }

    /* Create pktbuf pool entries, but only allocate on use  */
    int socket_count = rte_socket_count();
    for (int i = 0; i < socket_count; i++) {
        _cpu_rx_pktbuf_pools.push_back(NULL);
        _cpu_tx_pktbuf_pools.push_back(NULL);

        _gpu_rx_pktbuf_pools.push_back(NULL);
        _gpu_tx_pktbuf_pools.push_back(NULL);
    }
}

/**
 * Init DPDK environment, including DPDK's EAL.
 * This will make available information about the DPDK-assigned NIC devices.
 *
 * \param user_args User args passed in to override config files
 */
void dpdk_ctx::init(const device_addr_t& user_args)
{
    unsigned int i;
    std::lock_guard<std::mutex> lock(_init_mutex);
    if (!_init_done) {
        /* Gather global config, build args for EAL, and init UHD-DPDK */
        const device_addr_t dpdk_args = uhd::prefs::get_dpdk_args(user_args);
        UHD_LOG_TRACE("DPDK", "Configuration:" << std::endl << dpdk_args.to_pp_string());
        _eal_init(dpdk_args);

        UHD_LOG_TRACE("DPDK", "rte_lcore_count=" << rte_lcore_count());

        /* TODO: Should MTU be defined per-port? */
        _mtu = dpdk_args.cast<size_t>("dpdk_mtu", DEFAULT_FRAME_SIZE);
        /* This is per queue */
        _num_mbufs = dpdk_args.cast<int>("dpdk_num_mbufs", DEFAULT_NUM_MBUFS);
        _mbuf_cache_size =
            dpdk_args.cast<int>("dpdk_mbuf_cache_size", DEFAULT_MBUF_CACHE_SIZE);
        _gpu_id = dpdk_args.cast<size_t>("gpu_id", -1);
        UHD_LOG_TRACE("DPDK",
            "mtu: " << _mtu << " num_mbufs: " << _num_mbufs
                    << " mbuf_cache_size: " << _mbuf_cache_size << " gpu_id: " << _gpu_id);

        _link_init_timeout =
            dpdk_args.cast<int>("dpdk_link_timeout", DEFAULT_DPDK_LINK_INIT_TIMEOUT);

        /* GPU */
        uint16_t nb_gpus = rte_gpu_count_avail();

        if(nb_gpus == 0 || nb_gpus < _gpu_id) {
            //rte_exit(EXIT_FAILURE, "Error nb_gpus %d gpu_id %d\n", nb_gpus, gpu_id);
            UHD_LOG_ERROR("DPDK", "Invalid gpu_id!");
            throw uhd::runtime_error("Invalid gpu_id!");
        }

        printf("DPDK found %d GPUs:\n", nb_gpus);
        {
            int gpu_idx = 0;
            RTE_GPU_FOREACH(gpu_idx) {
                struct rte_gpu_info ginfo;
                if(rte_gpu_info_get(gpu_idx, &ginfo)) {
                    //rte_exit(EXIT_FAILURE, "rte_gpu_info_get error - bye\n");
                    UHD_LOG_ERROR("DPDK", "Can't rte_gpu_info_get");
                    throw uhd::runtime_error("Can't rte_gpu_info_get");
                }

                printf("\tID %d: parent ID %d GPU Bus ID %s NUMA node %d Memory %.02f MB Processors %d\n",
                        ginfo.dev_id,
                        ginfo.parent,
                        ginfo.name,
                        ginfo.numa_node,
                        (((float)ginfo.total_memory)/(float)1024)/(float)1024,
                        ginfo.processor_count
                    );
            }
        }

        /* Get device info for all the NIC ports */
        int num_dpdk_ports = rte_eth_dev_count_avail();
        if (num_dpdk_ports == 0) {
            UHD_LOG_ERROR("DPDK", "No available DPDK devices (ports) found!");
            throw uhd::runtime_error("No available DPDK devices (ports) found!");
        }
        device_addrs_t nics(num_dpdk_ports);
        RTE_ETH_FOREACH_DEV(i)
        {
            struct rte_ether_addr mac_addr;
            rte_eth_macaddr_get(i, &mac_addr);
            nics[i]["dpdk_mac"] = eth_addr_to_string(mac_addr);
        }

        /* Get user configuration for each NIC port */
        device_addrs_t args = separate_device_addr(user_args);
        size_t queue_count  = 0;
        RTE_ETH_FOREACH_DEV(i)
        {
            auto& nic = nics.at(i);
            for (const auto& arg : args) {
                /* Match DPDK-discovered NICs and user config via MAC addr */
                if (arg.has_key("dpdk_mac") && nic["dpdk_mac"] == arg["dpdk_mac"]) {
                    /* Copy user args for discovered NICs */
                    nic.update(arg, false);
                    break;
                }
            }
            /* Now combine user args with conf file */
            auto conf = uhd::prefs::get_dpdk_nic_args(nic);
            // TODO: Enable the use of multiple DMA queues
            conf["dpdk_num_queues"] = "1"; //!!!

            /* Update config, and remove ports that aren't fully configured */
            if (conf.has_key("dpdk_ipv4")) {
                nics[i] = conf;
                /* Update queue count, to generate a large enough mempool */
                queue_count += conf.cast<uint16_t>("dpdk_num_queues", 1);
            } else {
                nics[i] = device_addr_t();
            }
        }

        std::map<size_t, std::vector<size_t>> lcore_to_port_id_map;
        RTE_ETH_FOREACH_DEV(i)
        {
            auto& conf = nics.at(i);
            if (conf.has_key("dpdk_ipv4")) {
                UHD_ASSERT_THROW(conf.has_key("dpdk_lcore"));
                const size_t lcore_id = conf.cast<size_t>("dpdk_lcore", 0);
                if (!lcore_to_port_id_map.count(lcore_id)) {
                    lcore_to_port_id_map.insert({lcore_id, {}});
                }

                // Allocating enough buffers for all DMA queues for each CPU socket
                // - This is a bit inefficient for larger systems, since NICs may not
                //   all be on one socket
                auto cpu_socket = rte_eth_dev_socket_id(i);
                if (_gpu_id == -1) { //CPU only!
                    auto cpu_rx_pool = _get_cpu_rx_pktbuf_pool(cpu_socket, _num_mbufs * queue_count);
                    auto cpu_tx_pool = _get_cpu_tx_pktbuf_pool(cpu_socket, _num_mbufs * queue_count);
                    UHD_LOG_TRACE("DPDK",
                        "Initializing NIC(" << i << "):" << std::endl
                                            << conf.to_pp_string());
                    _ports[i] = dpdk_port::make(i,
                        _mtu,
                        conf.cast<uint16_t>("dpdk_num_queues", 1), //rx
                        conf.cast<uint16_t>("dpdk_num_queues", 1), //tx
                        conf.cast<uint16_t>("dpdk_num_desc", DPDK_DEFAULT_RING_SIZE),
                        cpu_rx_pool,
                        cpu_tx_pool,
                        NULL, //no gpu rx
                        NULL, //no gpu tx
                        conf["dpdk_ipv4"]);
                } else {
                    UHD_LOG_INFO("DPDK",
                        "Initializing NIC (" << i << ") and GPU(" << _gpu_id << "):" << std::endl
                                            << conf.to_pp_string());

                    auto cpu_rx_pool = _get_cpu_rx_pktbuf_pool(cpu_socket, _num_mbufs * queue_count);
                    auto cpu_tx_pool = _get_cpu_tx_pktbuf_pool(cpu_socket, _num_mbufs * queue_count);

                    struct rte_pktmbuf_extmem ext_mem; //GPU
                    ext_mem.elt_size = _mtu; //??? use SPP for mbuf size in bytes.
                    ext_mem.buf_len = RTE_ALIGN_CEIL(_num_mbufs * ext_mem.elt_size, GPU_PAGE_SIZE); //CEIL???
                    ext_mem.buf_iova = RTE_BAD_IOVA;

                    ext_mem.buf_ptr = rte_gpu_mem_alloc(_gpu_id, ext_mem.buf_len, CPU_PAGE_SIZE);
                    if (ext_mem.buf_ptr == NULL) {
                        UHD_LOG_ERROR("DPDK", "Could not allocate GPU device memory!");
                        throw uhd::runtime_error("Could not allocate GPU device memory!");
                    }

                    int ret = rte_extmem_register(ext_mem.buf_ptr, ext_mem.buf_len, NULL, ext_mem.buf_iova, GPU_PAGE_SIZE);
                    if (ret) {
                        UHD_LOG_ERROR("DPDK", "Unable to register extmem!");
                        throw uhd::runtime_error("Unable to register extmem!");
                    }

                    struct rte_eth_dev_info dev_info;
                    rte_eth_dev_info_get(i, &dev_info);

                    ret = rte_dev_dma_map(dev_info.device, ext_mem.buf_ptr, ext_mem.buf_iova, ext_mem.buf_len);
                    if (ret) {
                        UHD_LOG_ERROR("DPDK", "Could not DMA map EXT memory!");
                        throw uhd::runtime_error("Could not DMA map EXT memory!");
                    }

                    char pool_name[RTE_MEMPOOL_NAMESIZE];
                    snprintf(pool_name, sizeof(pool_name), "payload_mpool%i", i);
                    auto gpu_rx_pool = rte_pktmbuf_pool_create_extbuf(pool_name, _num_mbufs,
											0, 0, ext_mem.elt_size, 
											SOCKET_ID_ANY, &ext_mem, 1);
	                if (gpu_rx_pool == NULL) {
                        UHD_LOG_ERROR("DPDK", "Could not create EXT memory mempool!");
                        throw uhd::runtime_error("Could not create EXT memory mempool!");
                    }
                    
                    _ports[i] = dpdk_port::make(i,
                        _mtu,
                        conf.cast<uint16_t>("dpdk_num_queues", 1), //rx
                        conf.cast<uint16_t>("dpdk_num_queues", 1), //tx
                        conf.cast<uint16_t>("dpdk_num_desc", DPDK_DEFAULT_RING_SIZE),
                        cpu_rx_pool,
                        cpu_tx_pool,
                        gpu_rx_pool, //gpu rx
                        NULL, //gpu tx
                        conf["dpdk_ipv4"]);
                }

                // Remember all port IDs that map to an lcore
                lcore_to_port_id_map.at(lcore_id).push_back(i);
            }
        }

        UHD_LOG_TRACE("DPDK", "Waiting for links to come up...");
        do {
            bool all_ports_up = true;
            for (auto& port : _ports) {
                struct rte_eth_link link;
                auto portid = port.second->get_port_id();
                rte_eth_link_get(portid, &link);
                unsigned int link_status = link.link_status;
                unsigned int link_speed  = link.link_speed;
                UHD_LOGGER_TRACE("DPDK") << boost::format("Port %u UP: %d, %u Mbps")
                                                % portid % link_status % link_speed;
                all_ports_up &= (link.link_status == 1);
            }

            if (all_ports_up) {
                break;
            }

            rte_delay_ms(LINK_STATUS_INTERVAL);
            _link_init_timeout -= LINK_STATUS_INTERVAL;
            if (_link_init_timeout <= 0 && not all_ports_up) {
                UHD_LOG_ERROR("DPDK", "All DPDK links did not report as up!")
                throw uhd::runtime_error("DPDK: All DPDK links did not report as up!");
            }
        } while (true);

        UHD_LOG_TRACE("DPDK", "Init done -- spawning IO services");
        _init_done = true;

        // Links are up, now create one IO service per lcore
        for (auto& lcore_portids_pair : lcore_to_port_id_map) {
            const size_t lcore_id = lcore_portids_pair.first;
            std::vector<dpdk_port*> dpdk_ports;
            dpdk_ports.reserve(lcore_portids_pair.second.size());
            for (const size_t port_id : lcore_portids_pair.second) {
                dpdk_ports.push_back(get_port(port_id));
            }
            const size_t servq_depth = 32; // FIXME
            UHD_LOG_TRACE("DPDK",
                "Creating I/O service for lcore "
                    << lcore_id << ", servicing " << dpdk_ports.size()
                    << " ports, service queue depth " << servq_depth);
            _io_srv_portid_map.insert(
                {uhd::transport::dpdk_io_service::make(lcore_id, dpdk_ports, servq_depth),
                    lcore_portids_pair.second});
        }
    }
}

void dpdk_port::to_cpu()
{
    if (_gpu_rx_pktbuf_pool != NULL) {
        //enqueue all traffic to CPU queue 0

        struct rte_flow_error flow_error;
        int retval;

        UHD_ASSERT_THROW(_flow);

        retval = rte_flow_destroy(_port, _flow, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to destroy cpu flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to destroy cpu flow");
        }
        
        //flow attr ingress
        struct rte_flow_attr attr;
        memset(&attr, 0, sizeof(attr));
        attr.ingress = 1;

        //flow action
        struct rte_flow_action action[2];
        memset(action, 0, sizeof(action));
        action[0].type = RTE_FLOW_ACTION_TYPE_QUEUE;
        struct rte_flow_action_queue queue;
        queue.index = 0; //last is GPU queue!
        action[0].conf = &queue;
        action[1].type = RTE_FLOW_ACTION_TYPE_END;

        //flow pattern (empty)
        struct rte_flow_item pattern[1 /*END*/];
        memset(pattern, 0, sizeof(pattern));
        
        pattern[0].type = RTE_FLOW_ITEM_TYPE_END;
        
        retval = rte_flow_validate(_port, &attr, pattern, action, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to validate flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to validate flow");
        }
        _flow = rte_flow_create(_port, &attr, pattern, action, &flow_error);
        if (_flow == NULL) {
            UHD_LOG_ERROR("DPDK", "Failed to create flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to create flow");
        }

        UHD_LOG_TRACE("DPDK", "Flow to CPU created!");
    }
}

void dpdk_port::to_gpu()
{
    if (_gpu_rx_pktbuf_pool != NULL) {
        //last queue to GPU with DPDK flow api
        uint16_t gpu_queue = _num_rx_queues-1;
        /* 
            https://community.mellanox.com/s/question/0D51T00006aYXHzSAO/dpdk-rteflow-is-degrading-performance-when-testing-on-connect-x5-100g-en-100g

            DEV_TX_OFFLOAD_VLAN_INSERT
            DEV_TX_OFFLOAD_TCP_TSO
        */

        struct rte_flow_error flow_error;
        int retval;

        UHD_ASSERT_THROW(_flow);

        retval = rte_flow_destroy(_port, _flow, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to destroy gpu flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to destroy gpu flow");
        }

        //X300_VITA_UDP_PORT 49153 -> GPU
        
        //flow attr ingress
        struct rte_flow_attr attr;
        memset(&attr, 0, sizeof(attr));
        attr.ingress = 1;

        //flow action
        struct rte_flow_action action[2];
        memset(action, 0, sizeof(action));
        action[0].type = RTE_FLOW_ACTION_TYPE_QUEUE;
        struct rte_flow_action_queue queue;
        queue.index = gpu_queue; //last is GPU queue!
        //queue.index = 0; //to CPU!!!
        action[0].conf = &queue;
        action[1].type = RTE_FLOW_ACTION_TYPE_END;

        //flow pattern (UDP source port is X300_VITA_UDP_PORT)
        //struct rte_flow_item pattern[1 /*ETH*/ + 1 /*IPv4*/ + 1 /*UDP*/ + 1 /*CHDR (RAW)*/ + 1 /*END*/]; //Mellanox currently does not support RTE_FLOW_ITEM_TYPE_RAW
        struct rte_flow_item pattern[1 /*ETH*/ + 1 /*IPv4*/ + 1 /*UDP*/ + 1 /*END*/];
        memset(pattern, 0, sizeof(pattern));
        
        pattern[0].type = RTE_FLOW_ITEM_TYPE_ETH;
        
        pattern[1].type = RTE_FLOW_ITEM_TYPE_IPV4;
        struct rte_flow_item_ipv4 ip4_spec;
        memset(&ip4_spec, 0, sizeof(ip4_spec));
        ip4_spec.hdr.next_proto_id = IPPROTO_UDP;
        //ip4_spec.hdr.total_length = RTE_BE16(8044);
        struct rte_flow_item_ipv4 ip4_mask;
        pattern[1].spec = &ip4_spec;
        memset(&ip4_mask, 0, sizeof(ip4_mask));
        ip4_mask.hdr.next_proto_id = 0xff;
        //ip4_mask.hdr.total_length = RTE_BE16(0xffff);
        pattern[1].mask = &ip4_mask;
        
        //Mellanox currently does not support RTE_FLOW_ITEM_TYPE_RAW... try to use the dgram_len value from UDP header to determine DATA CHDR packet? Ops... Mellanox currently does not support this! rte_flow_error: mask enables non supported bits
        pattern[2].type = RTE_FLOW_ITEM_TYPE_UDP;
        static struct rte_flow_item_udp udp_spec;
        memset(&udp_spec, 0, sizeof(udp_spec));
        udp_spec.hdr.src_port = RTE_BE16(X300_VITA_UDP_PORT);
        //udp_spec.hdr.dst_port = RTE_BE16(65533); //DPDK uses ports 65533 DATA, 65534 CONTROL, 65535 DISCOVERY
        //udp_spec.hdr.dgram_len = RTE_BE16(8016 + 8 /*CHDR header*/); //use SPP!!! //Mellanox currently does not support this! 8( rte_flow_error: mask enables non supported bits
        pattern[2].spec = &udp_spec;
        static struct rte_flow_item_udp udp_mask;
        memset(&udp_mask, 0, sizeof(udp_mask));
        udp_mask.hdr.src_port = RTE_BE16(0xffff);
        //udp_mask.hdr.dst_port = RTE_BE16(0xffff);
        //udp_mask.hdr.dgram_len = RTE_BE16(0xffff); //Mellanox currently does not support this! 8( rte_flow_error: mask enables non supported bits
        pattern[2].mask = &udp_mask;

        /*
        //Mellanox currently does not support RTE_FLOW_ITEM_TYPE_RAW items 8(
        pattern[3].type = RTE_FLOW_ITEM_TYPE_RAW;
        static struct rte_flow_item_raw raw_spec;
        memset(&raw_spec, 0, sizeof(raw_spec));
        raw_spec.relative = 1;
        raw_spec.offset = 6;
        raw_spec.length = 1;
        const uint8_t raw_spec_pattern = 0xe0; //Data with Timestamp
        raw_spec.pattern = &raw_spec_pattern;
        pattern[3].spec = &raw_spec;
        //static struct rte_flow_item_raw raw_mask;
        //memset(&raw_mask, 0, sizeof(raw_mask));
        //raw_mask.offset = 6;
        //raw_mask.length = 1;
        //const uint8_t raw_mask_pattern = 0xff;
        //raw_mask.pattern = &raw_mask_pattern;
        //pattern[3].mask = &raw_mask;

        pattern[4].type = RTE_FLOW_ITEM_TYPE_END;
        */
        pattern[3].type = RTE_FLOW_ITEM_TYPE_END;

        retval = rte_flow_validate(_port, &attr, pattern, action, &flow_error);
        if (retval) {
            UHD_LOG_ERROR("DPDK", "Failed to validate flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to validate flow");
        }
        _flow = rte_flow_create(_port, &attr, pattern, action, &flow_error);
        if (_flow == NULL) {
            UHD_LOG_ERROR("DPDK", "Failed to create flow (error=" << flow_error.type << "): " << flow_error.message);
            throw uhd::runtime_error("DPDK: Failed to create flow");
        }
    }
}

dpdk_port* dpdk_ctx::get_port(port_id_t port) const
{
    assert(is_init_done());
    if (_ports.count(port) == 0) {
        return nullptr;
    }
    return _ports.at(port).get();
}

dpdk_port* dpdk_ctx::get_port(struct rte_ether_addr mac_addr) const
{
    assert(is_init_done());
    for (const auto& port : _ports) {
        struct rte_ether_addr port_mac_addr;
        rte_eth_macaddr_get(port.first, &port_mac_addr);
        for (int j = 0; j < 6; j++) {
            if (mac_addr.addr_bytes[j] != port_mac_addr.addr_bytes[j]) {
                break;
            }
            if (j == 5) {
                return port.second.get();
            }
        }
    }
    return nullptr;
}

int dpdk_ctx::get_port_count(void)
{
    assert(is_init_done());
    return _ports.size();
}

void dpdk_ctx::to_gpu()
{
    for (const auto& port : _ports) {
        auto p = port.second.get();

        p->to_gpu();
    }
}

void dpdk_ctx::to_cpu()
{
    for (const auto& port : _ports) {
        auto p = port.second.get();

        p->to_cpu();
    }
}

int dpdk_ctx::get_port_rx_queue_count(port_id_t portid)
{
    assert(is_init_done());
    return _ports.at(portid)->get_rx_queue_count();
}

int dpdk_ctx::get_port_tx_queue_count(port_id_t portid)
{
    assert(is_init_done());
    return _ports.at(portid)->get_tx_queue_count();
}

int dpdk_ctx::get_port_link_status(port_id_t portid) const
{
    struct rte_eth_link link;
    rte_eth_link_get_nowait(portid, &link);
    return link.link_status;
}

dpdk_port* dpdk_ctx::get_route(const std::string& addr) const
{
    const uint32_t dst_ipv4 = (uint32_t)inet_addr(addr.c_str());
    for (const auto& port : _ports) {
        if (get_port_link_status(port.first) < 1)
            continue;
        uint32_t src_ipv4 = port.second->get_ipv4();
        uint32_t netmask  = port.second->get_netmask();
        if ((src_ipv4 & netmask) == (dst_ipv4 & netmask)) {
            return port.second.get();
        }
    }
    return NULL;
}


bool dpdk_ctx::is_init_done(void) const
{
    return _init_done.load();
}

uhd::transport::dpdk_io_service::sptr dpdk_ctx::get_io_service(const size_t port_id)
{
    for (auto& io_srv_portid_pair : _io_srv_portid_map) {
        if (uhd::has(io_srv_portid_pair.second, port_id)) {
            return io_srv_portid_pair.first;
        }
    }

    std::string err_msg = std::string("Cannot look up I/O service for port ID: ")
                          + std::to_string(port_id) + ". No such port ID!";
    UHD_LOG_ERROR("DPDK", err_msg);
    throw uhd::lookup_error(err_msg);
}

struct rte_mempool* dpdk_ctx::_get_cpu_rx_pktbuf_pool(
    unsigned int cpu_socket, size_t num_bufs)
{
    if (!_cpu_rx_pktbuf_pools.at(cpu_socket)) {

        const int mbuf_size = _mtu + RTE_PKTMBUF_HEADROOM +
        RTE_ETHER_HDR_LEN + RTE_ETHER_CRC_LEN;

/*
        const int mbuf_size = RTE_PKTMBUF_HEADROOM 
        + RTE_ETHER_HDR_LEN + RTE_ETHER_CRC_LEN 
        + 16; //CHDR header + timestamp
*/
        char name[32];
        snprintf(name, sizeof(name), "cpu_rx_mbuf_pool_%u", cpu_socket);
        _cpu_rx_pktbuf_pools[cpu_socket] = rte_pktmbuf_pool_create(name,
            num_bufs,
            _mbuf_cache_size,
            DPDK_MBUF_PRIV_SIZE,
            mbuf_size,
            SOCKET_ID_ANY);
        if (!_cpu_rx_pktbuf_pools.at(cpu_socket)) {
            UHD_LOG_ERROR("DPDK", "Could not allocate CPU RX pktbuf pool");
            throw uhd::runtime_error("DPDK: Could not allocate CPU RX pktbuf pool");
        }
    }
    return _cpu_rx_pktbuf_pools.at(cpu_socket);
}

struct rte_mempool* dpdk_ctx::_get_cpu_tx_pktbuf_pool(
    unsigned int cpu_socket, size_t num_bufs)
{
    if (!_cpu_tx_pktbuf_pools.at(cpu_socket)) {

        const int mbuf_size = _mtu + RTE_PKTMBUF_HEADROOM +
        RTE_ETHER_HDR_LEN + RTE_ETHER_CRC_LEN;

/*
        const int mbuf_size = RTE_PKTMBUF_HEADROOM 
        + RTE_ETHER_HDR_LEN + RTE_ETHER_CRC_LEN 
        + 16; //CHDR header + timestamp
*/
        char name[32];
        snprintf(name, sizeof(name), "cpu_tx_mbuf_pool_%u", cpu_socket);
        _cpu_tx_pktbuf_pools[cpu_socket] = rte_pktmbuf_pool_create(
            name, num_bufs, _mbuf_cache_size, 0, mbuf_size, SOCKET_ID_ANY);
        if (!_cpu_tx_pktbuf_pools.at(cpu_socket)) {
            UHD_LOG_ERROR("DPDK", "Could not allocate CPU TX pktbuf pool");
            throw uhd::runtime_error("DPDK: Could not allocate CPU TX pktbuf pool");
        }
    }
    return _cpu_tx_pktbuf_pools.at(cpu_socket);
}

}}} // namespace uhd::transport::dpdk
