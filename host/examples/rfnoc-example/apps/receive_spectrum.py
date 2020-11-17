import uhd
import numpy
import argparse
import matplotlib
from matplotlib import pyplot

parser = argparse.ArgumentParser()
parser.add_argument("-a", "--args", default="", type=str)
parser.add_argument("-l", "--fft_len", default=256, type=int)
args = parser.parse_args()

graph = uhd.rfnoc.RfnocGraph(args.args)

radio_block = uhd.rfnoc.RadioControl(graph.get_block("0/Radio#0"))
radio_block.set_rx_gain(65, 0)
radio_block.set_rx_antenna("RX2", 0)
radio_block.set_rx_frequency(2.437E9, 0)
radio_block.set_rate(200E6)

ddc_block = uhd.rfnoc.DdcBlockControl(graph.get_block("0/DDC#0"))
ddc_block.set_output_rate(5E6, 0)

fft_block = uhd.rfnoc.FftBlockControl(graph.get_block("0/FFT#0"))
fft_block.set_length(args.fft_len)
fft_block.set_scaling(args.fft_len)
fft_block.set_magnitude(uhd.libpyuhd.rfnoc.fft_magnitude.MAGNITUDE)

stream_args = uhd.usrp.StreamArgs("fc32", "sc16")

rx_streamer = graph.create_rx_streamer(1, stream_args)

graph.connect(radio_block.get_unique_id(), 0, ddc_block.get_unique_id(), 0, False)
graph.connect(ddc_block.get_unique_id(), 0, rx_streamer, 0)
graph.commit()

rx_md = uhd.types.RXMetadata()

num_samples = int(10*ddc_block.get_output_rate(0))
rx_data = numpy.zeros((1, num_samples), dtype="complex64")

stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.num_done)
stream_cmd.num_samps = num_samples
stream_cmd.stream_now = False
stream_cmd.time_spec = graph.get_mb_controller(0).get_timekeeper(0).get_time_now() + 10

rx_streamer.issue_stream_cmd(stream_cmd)

num_recv = rx_streamer.recv(rx_data, rx_md, 15)

matplotlib.pyplot.plot(range(numpy.size(rx_data[0])), numpy.real(rx_data[0]), "g", range(numpy.size(rx_data[0])), numpy.imag(rx_data[0]), "r")
pyplot.show()
#[print(i, end=", ") for i in rx_data]
#print()
#print(num_recv)
