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
    uint32_t fft_len;

    // setup the program options
    po::options_description desc("Allowed options");
    // clang-format off
    desc.add_options()
        ("help", "help message")
        ("args", po::value<std::string>(&args)->default_value(""), "USRP device address args")
        ("fft_len", po::value<uint32_t>(&fft_len)->default_value(256), "FFT length")
    ;
    // clang-format on
    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    // print the help message
    if (vm.count("help")) {
        std::cout << "Test FFT block " << desc << std::endl;
        std::cout << std::endl
                  << "This application searches an FFT block on a USRP, "
                     "sends a dirac delta to the FFT and receives and "
		     "prints the FFT result.\n"
                  << std::endl;
        return EXIT_SUCCESS;
    }

    // Create RFNoC graph object:
    auto graph = uhd::rfnoc::rfnoc_graph::make(args);

    uhd::rfnoc::block_id_t fft_id(0, "FFT", 0);
    auto fft_block =
        graph->get_block<uhd::rfnoc::fft_block_control>(fft_id);
    if (!fft_block) {
        std::cout << "ERROR: Failed to extract block controller!" << std::endl;
        return EXIT_FAILURE;
    }
    fft_block->set_length(fft_len);
    fft_block->set_scaling(fft_len);
    fft_block->set_magnitude(uhd::rfnoc::fft_magnitude::MAGNITUDE);

    uhd::stream_args_t stream_args("fc32", "sc16");
    uhd::tx_streamer::sptr tx_stream;
    uhd::rx_streamer::sptr rx_stream;
    uhd::tx_metadata_t tx_md;
    uhd::rx_metadata_t rx_md;

    tx_stream = graph->create_tx_streamer(1, stream_args);
    rx_stream = graph->create_rx_streamer(1, stream_args);
    graph->connect(tx_stream, 0, fft_block->get_block_id(), 0);
    graph->connect(fft_block->get_block_id(), 0, rx_stream, 0);
    graph->commit();

    
    std::vector<std::complex<float>> data(fft_len);
    data[0] = std::complex<float>(1.0, 0.0);
    tx_md.start_of_burst = true;
    tx_md.end_of_burst = true;
    tx_stream->send(&data[0], fft_len, tx_md);


    std::vector<std::complex<float>> buff(fft_len);

    size_t num_rx_samps = rx_stream->recv(&buff.front(), buff.size(), rx_md, 1.0, false);
    for (size_t i = 0; i < num_rx_samps; i++) {
        std::cout << buff[i] << " ";
    }
    std::cout << std::endl;
    return EXIT_SUCCESS;
}
