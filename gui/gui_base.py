from tkinter import filedialog
from tkinter import messagebox

from gui.config import *

VERSION_NUMBER = "5.12"
PROGRAM_TITLE = "Tesstrain GUI"
firstColumnWidth = 225
secondColumnWidth = 370
rowHeight = 19


class Gui:
    root = tk.Tk()
    root.title(PROGRAM_TITLE)
    load_config()
    current_parent = root
    current_row = -1

    # main level Gui entry creators

    def add_folder_selection_row(self, target_config, title, description, callback=None, allow_change=True):
        Gui.current_row += 1
        self.add_label(title)
        self.add_entry(target_config)
        if allow_change:
            self.add_button("Change", command=lambda: select_folder(callback), config_key=target_config)
        self.add_description(description, title)

    def add_file_selection_row(self, target_config, title, description, callback=None, allow_change=True):
        Gui.current_row += 1
        self.add_label(title)
        self.add_entry(target_config)
        if allow_change:
            self.add_button("Change", command=lambda: select_file(callback), config_key=target_config)
        self.add_description(description, title)

    def add_edit_box_row(self, target_config, title, description):
        Gui.current_row += 1
        self.add_label(title)
        self.add_entry(target_config)
        self.add_description(description, title)

    def add_integer_row(self, target_config, title, description):
        Gui.current_row += 1
        self.add_label(title)
        self.add_entry(target_config)
        self.add_description(description, title)

    def add_float_selection_row(self, target_config, title, description):
        Gui.current_row += 1
        self.add_label(title)
        self.add_entry(target_config)
        self.add_description(description, title)

    def add_drop_down_selection_row(self, target_config, title, choices, description):
        Gui.current_row += 1
        self.add_label(title)
        self.add_drop_down(target_config, choices)
        self.add_description(description, title)

    def add_checkbox_row(self, target_config, title, description):
        Gui.current_row += 1
        self.add_label(title)
        self.add_checkbox(target_config)
        self.add_description(description, title)

    def add_slider_row(self, target_config, title, description):
        Gui.current_row += 1
        self.add_label(title)
        self.add_slider(target_config)
        self.add_description(description, title)

    # Entry creators helper methods

    def add_label(self, text):
        label = tk.Label(self.current_parent, text=text)
        label.grid(column=0, row=Gui.current_row, sticky=tk.E)

    def add_entry(self, config_key):
        entry = tk.Entry(self.current_parent, textvariable=Config[config_key])
        entry.grid(column=1, row=Gui.current_row, sticky=tk.E+tk.W)

    def add_checkbox(self, config_key):
        entry = tk.Checkbutton(self.current_parent, variable=Config[config_key])
        entry.grid(column=1, row=Gui.current_row, sticky=tk.W)

    def add_slider(self, config_key):
        entry = tk.Scale(self.current_parent, variable=Config[config_key], from_=1, to=99, orient=tk.HORIZONTAL)
        entry.grid(column=1, row=Gui.current_row, sticky=tk.E+tk.W)

    def add_drop_down(self, target_name, choices):
        variable = Config[target_name]
        if variable.get() == "":
            variable.set(choices[0])
        question_menu = tk.OptionMenu(self.current_parent, variable, *choices)
        question_menu.grid(column=1, row=Gui.current_row, sticky=tk.W)

    def add_button(self, text, command, config_key):
        button = tk.Button(self.current_parent, text=text, command=lambda: Config[config_key].set(command()))
        button.grid(column=2, row=Gui.current_row, sticky=tk.W)

    def add_description(self, text, title):
        description_button = tk.Button(self.current_parent, text="?", command=lambda: messagebox.showinfo(title, text))
        description_button.grid(column=3, row=Gui.current_row)

    def add_root_button(self, text, callback):
        button = tk.Button(self.root, text=text, command=callback)
        button.pack(side=tk.LEFT)


# global helper functions

def select_folder(callback=None):
    new_directory = filedialog.askdirectory()
    if callback is not None:
        callback(new_directory)
    return new_directory


def select_file(callback=None):
    new_file = filedialog.askopenfile()
    if callback is not None:
        callback(new_file)
    return new_file
