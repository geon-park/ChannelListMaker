class ChannelListMaker:
    def __init__(self):
        self.priority = 10

    def make_channel_list(self, channel_list, priority):
        self.priority = priority
        epg_channels = ''
        m3u_channels = '#EXTM3U' + '\n'
        for channel in channel_list:
            if self.priority < int(channel['ch_priority']):
                continue

            m3u_channels += '#EXTINF:-1 tvg-id="{0}" tvg-logo="{1}" tvh-chnum="{2}",{3}'.format(
                channel['ch_id'], channel['ch_icon'], channel['ch_num'], channel['ch_name']) + '\n'
            m3u_channels += channel['ch_address'] + '\n'

            epg_channels += channel['ch_id'] + ', '
        epg_channels = epg_channels[:-2]
        return m3u_channels, epg_channels
