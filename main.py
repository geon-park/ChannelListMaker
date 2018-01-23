import sys
import csv
from collections import OrderedDict

from channellistmaker import ChannelListMaker
from PyQt5.QtWidgets import *


class ChannelListWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        self.header_list = ['ch_num', 'ch_id', 'ch_name', 'ch_address', 'ch_icon', 'ch_priority']
        self.channel_list = []

        # Layout
        grid = QGridLayout()
        grid.setSpacing(10)

        # path area
        self.file_path = QLineEdit('')
        self.file_path.setReadOnly(True)
        self.file_open = QPushButton('Open')
        self.file_open.clicked.connect(self.open_button_clicked)

        grid.addWidget(self.file_path, 0, 0, 1, 3)
        grid.addWidget(self.file_open, 0, 3, 1, 1)

        # channel area
        self.list_channels = QTableWidget(0, 6, self)
        self.list_channels.setHorizontalHeaderLabels(self.header_list)
        column_widths = [100, 100, 250, 150, 250, 100]
        for i, width in enumerate(column_widths):
            self.list_channels.setColumnWidth(i, width)
        grid.addWidget(self.list_channels, 1, 0, 4, 4)

        # option area
        self.label_priority = QLabel('Minimum Priority')
        grid.addWidget(self.label_priority, 5, 0, 1, 1)
        self.combo_priority = QComboBox()
        grid.addWidget(self.combo_priority, 5, 1, 1, 1)
        for i in range(1, 11):
            self.combo_priority.addItem(str(i))
        self.combo_priority.currentIndexChanged.connect(self.priority_combo_index_changed)
        self.button_make = QPushButton('Make')
        self.button_make.clicked.connect(self.make_button_clicked)
        self.button_save = QPushButton('Save')
        self.button_save.clicked.connect(self.save_button_clicked)
        grid.addWidget(self.button_make, 5, 2, 1, 1)
        grid.addWidget(self.button_save, 5, 3, 1, 1)

        # m3u area
        self.edit_m3u = QTextEdit()
        grid.addWidget(self.edit_m3u, 6, 0, 4, 4)

        # epg channel area
        self.text_channels = QLineEdit('')
        self.text_channels.setReadOnly(True)
        grid.addWidget(self.text_channels, 10, 0, 1, 4)

        window = QWidget()
        window.setLayout(grid)
        self.setCentralWidget(window)

        self.setGeometry(300, 300, 1200, 900)
        self.setWindowTitle('Channel List Maker')
        self.show()

    def open_button_clicked(self):
        file_names = QFileDialog.getOpenFileName(filter='All Files (*.*);;CSV Files (*.csv)')
        if file_names[0]:
            self.clear_data_list()
            self.file_path.setText(file_names[0])
            with open(file_names[0], 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for line in reader:
                    row = self.list_channels.rowCount()
                    self.list_channels.insertRow(row)

                    for j, header in enumerate(self.header_list):
                        self.list_channels.setItem(row, j, QTableWidgetItem(line[header]))

    def save_button_clicked(self):
        file_names = QFileDialog.getSaveFileName(self, caption='Save File')
        if file_names[0]:
            with open(file_names[0], 'w', encoding='utf-8') as f:
                f.write(self.edit_m3u.toPlainText())

    def priority_combo_index_changed(self):
        pass

    def make_button_clicked(self):
        if self.list_channels.rowCount() == 0:
            return

        self.edit_m3u.setText('')
        self.text_channels.setText('')
        self.make_channel_list()

    def clear_data_list(self):
        self.list_channels.setRowCount(0)

    def make_channel_list(self):
        channel_list = []
        for i in range(self.list_channels.rowCount()):
            channel = OrderedDict()
            for j in range(self.list_channels.columnCount()):
                header_name = self.list_channels.horizontalHeaderItem(j).text()
                channel[header_name] = self.list_channels.item(i, j).text()
            channel_list.append(channel)

        priority = int(self.combo_priority.currentText())
        maker = ChannelListMaker()
        m3u_channels, epg_channels = maker.make_channel_list(channel_list, priority)
        self.edit_m3u.setText(m3u_channels)
        self.text_channels.setText(epg_channels)


if __name__ == '__main__':
    app = QApplication(sys.argv)
    ex = ChannelListWindow()
    sys.exit(app.exec())
