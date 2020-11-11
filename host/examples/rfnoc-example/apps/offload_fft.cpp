//
// Copyright 2019 Ettus Research, a National Instruments Brand
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

// Example application to show how to write applications that depend on both UHD
// and out-of-tree RFNoC modules.
//
// It will see if a USRP is runnging the gain block, if so, it will test to see
// if it can change the gain.

#include <complex>
#include <uhd/exception.hpp>
#include <uhd/rfnoc_graph.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/rfnoc/fft_block_control.hpp>
#include <boost/program_options.hpp>

namespace po = boost::program_options;

int UHD_SAFE_MAIN(int argc, char* argv[])
{
    std::string args;

    // setup the program options
    po::options_description desc("Allowed options");
    // clang-format off
    desc.add_options()
        ("help", "help message")
        ("args", po::value<std::string>(&args)->default_value(""), "USRP device address args")
    ;
    // clang-format on
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    // print the help message
    if (vm.count("help")) {
        std::cout << "Init RFNoC gain block " << desc << std::endl;
        std::cout << std::endl
                  << "This application attempts to find a gain block in a USRP "
                     "and tries to peek/poke registers..\n"
                  << std::endl;
        return EXIT_SUCCESS;
    }

    // Create RFNoC graph object:
    auto graph = uhd::rfnoc::rfnoc_graph::make(args);

    auto fft_blocks = graph->find_blocks<uhd::rfnoc::fft_block_control>("");
    if (fft_blocks.empty()) {
        std::cout << "No FFT block found." << std::endl;
        return EXIT_FAILURE;
    }

    auto fft_block =
        graph->get_block<uhd::rfnoc::fft_block_control>(fft_blocks.front());
    if (!fft_block) {
        std::cout << "ERROR: Failed to extract block controller!" << std::endl;
        return EXIT_FAILURE;
    }
    std::cout << fft_block->get_length() << std::endl;

    uhd::device_addr_t streamer_args;
    uhd::stream_args_t stream_args("fc32", "sc16");
    //stream_args.args = "spp=256";
    uhd::tx_streamer::sptr tx_stream;
    uhd::tx_metadata_t tx_md;

    streamer_args["block_id"]   = fft_block->get_block_id().to_string();
    streamer_args["block_port"] = std::to_string(0);
    stream_args.args            = streamer_args;
    stream_args.channels        = {0};
    tx_stream = graph->create_tx_streamer(stream_args.channels.size(), stream_args);
    uhd::stream_args_t rx_stream_args(
        "sc16", "sc16"); // We should read the wire format from the blocks
    stream_args.args = streamer_args;
    uhd::rx_streamer::sptr rx_stream = graph->create_rx_streamer(1, stream_args);
    graph->connect(tx_stream, 0, fft_block->get_block_id(), 0);
    graph->connect(fft_block->get_block_id(), 0, rx_stream, 0);
    graph->commit();

    std::vector<std::complex<float>> data(256);
    data[128] = std::complex<float>(1.0, 1.0);
    tx_md.start_of_burst = true;
    tx_md.end_of_burst = true;
    std::cout << tx_stream->send(&data[0], 256, tx_md) << std::endl;


    std::vector<std::complex<float>> buff(256);
    uhd::rx_metadata_t rx_md;
    // create a receive streamer
    // std::cout << "Samples per packet: " << spp << std::endl;
    //std::cout << "Using streamer args: " << stream_args.args.to_string() << std::endl;
    //uhd::stream_cmd_t stream_cmd(uhd::stream_cmd_t::STREAM_MODE_NUM_SAMPS_AND_DONE);
    //stream_cmd.num_samps  = 256;
    //stream_cmd.stream_now = true;
    //stream_cmd.time_spec  = uhd::time_spec_t();
    //std::cout << "Issuing stream cmd" << std::endl;
    //rx_stream->issue_stream_cmd(stream_cmd);

    size_t num_rx_samps = rx_stream->recv(&buff.front(), buff.size(), rx_md, 3.0, false);
    std::cout << num_rx_samps <<std::endl;
    for (size_t i = 0; i < num_rx_samps; i++) {
        std::cout << buff[i] << " ";
    }
    std::cout << std::endl;
    return EXIT_SUCCESS;
}
