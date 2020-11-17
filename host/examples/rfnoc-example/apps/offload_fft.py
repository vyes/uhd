import argparse
import uhd
import numpy


parser = argparse.ArgumentParser()
parser.add_argument("-a", "--args", default="", type=str)
parser.add_argument("-l", "--fft_len", default=256, type=int)
args = parser.parse_args()

graph = uhd.rfnoc.RfnocGraph(args.args)
fft_block = uhd.rfnoc.FftBlockControl(graph.get_block("0/FFT#0"))
fft_block.set_length(args.fft_len)
fft_block.set_scaling(args.fft_len)
fft_block.set_magnitude(uhd.libpyuhd.rfnoc.fft_magnitude.MAGNITUDE)

stream_args = uhd.usrp.StreamArgs("fc32", "sc16")

tx_streamer = graph.create_tx_streamer(1, stream_args)
rx_streamer = graph.create_rx_streamer(1, stream_args)

graph.connect(tx_streamer, 0, fft_block.get_unique_id(), 0)
graph.connect(fft_block.get_unique_id(), 0, rx_streamer, 0)
graph.commit()

tx_data = numpy.zeros((1, args.fft_len), dtype=numpy.complex64)
tx_data[0, 0] = (1.0j + 0)

tx_md = uhd.types.TXMetadata()
tx_md.start_of_burst = True
tx_md.end_of_burst = True

num_sent = tx_streamer.send(tx_data, tx_md)

rx_md = uhd.types.RXMetadata()

rx_data = numpy.zeros((1, args.fft_len), dtype=numpy.complex64)
num_recv = rx_streamer.recv(rx_data, rx_md, 1)

[print(i, end=", ") for i in rx_data]
print()
