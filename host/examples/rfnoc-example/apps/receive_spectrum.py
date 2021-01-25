import uhd
import numpy
import argparse
import matplotlib
from matplotlib import pyplot

parser = argparse.ArgumentParser()
parser.add_argument("-a", "--args", default="", type=str)
parser.add_argument("-l", "--fft_len", default=64, type=int)
args = parser.parse_args()

graph = uhd.rfnoc.RfnocGraph(args.args)

radio_block = uhd.rfnoc.RadioControl(graph.get_block("0/Radio#0"))
ddc_block = uhd.rfnoc.DdcBlockControl(graph.get_block("0/DDC#0"))
fft_block = uhd.rfnoc.FftBlockControl(graph.get_block("0/FFT#0"))

stream_args = uhd.usrp.StreamArgs("fc32", "sc16")
rx_streamer = graph.create_rx_streamer(1, stream_args)

graph.connect(radio_block.get_unique_id(), 0, ddc_block.get_unique_id(), 0, False)
graph.connect(ddc_block.get_unique_id(), 0, fft_block.get_unique_id(), 0, False)
graph.connect(fft_block.get_unique_id(), 0, rx_streamer, 0)
graph.commit()

freq = 2.437E9
bw = 20E6
radio_block.set_rx_gain(20, 0)
radio_block.set_rx_antenna("RX2", 0)
radio_block.set_rx_bandwidth(bw, 0)
radio_block.set_rx_frequency(freq, 0)
radio_block.set_rate(200E6)
radio_block.set_properties("spp={0}".format(args.fft_len), 0)

ddc_block.set_freq(freq - radio_block.get_rx_frequency(0), 0)
ddc_block.set_input_rate(bw, 0)
ddc_block.set_output_rate(bw, 0)

fft_block.set_direction(uhd.libpyuhd.rfnoc.fft_direction.FORWARD)
fft_block.set_length(args.fft_len)
fft_block.set_scaling(1)
#fft_block.set_magnitude(uhd.libpyuhd.rfnoc.fft_magnitude.MAGNITUDE)
fft_block.set_shift_config(uhd.libpyuhd.rfnoc.fft_shift.NORMAL)

rx_md = uhd.types.RXMetadata()

num_samples = int(0.1*ddc_block.get_output_rate(0))
rx_data = numpy.zeros((1, num_samples), dtype="complex64")

stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.num_done)
stream_cmd.num_samps = num_samples
stream_cmd.stream_now = False
stream_cmd.time_spec = graph.get_mb_controller(0).get_timekeeper(0).get_time_now() + 1

rx_streamer.issue_stream_cmd(stream_cmd)

num_recv = rx_streamer.recv(rx_data, rx_md, 5)

with open("/tmp/raw", "wb") as f:
    numpy.save(f, rx_data)

matplotlib.pyplot.plot(range(numpy.size(rx_data[0])), numpy.real(rx_data[0]), "g", range(numpy.size(rx_data[0])), numpy.imag(rx_data[0]), "r")
#matplotlib.rcParams['agg.path.chunksize'] = 10000
pyplot.show()
