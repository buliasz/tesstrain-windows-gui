import tkinter
from tkinter import ttk
from gui.gui_base import Gui

SUPPORTED_IMAGE_FILES = [".bin.png", ".nrm.png", ".png", ".tif", ".bmp"]


class TesstrainGui(Gui):
    def show(self):
        tabs = ttk.Notebook(self.root)
        tab1 = ttk.Frame(tabs)
        tab1.columnconfigure(1, weight=1)
        tab2 = ttk.Frame(tabs)
        tab2.columnconfigure(1, weight=1)
        tabs.add(tab1, text='Main settings')
        tabs.add(tab2, text='Advanced')
        tabs.pack(expand=1, fill=tkinter.BOTH)
        self.current_parent = tab1

        self.add_folder_selection_row(
            "BIN_DIR",
            "Tesseract executables folder",
            "A path to Tesseract executable files containing 'tesseract', 'combine_tessdata', 'unicharset_extractor', "
            + "'merge_unicharsets', 'lstmtraining' and 'combine_lang_model' executables.",
            callback=on_bin_dir_change
        )
        self.add_folder_selection_row(
            "TESSDATA",
            "TessData folder (containing '.traineddata' files)",
            "Path to the '.traineddata' directory with traineddata suitable for training (for example from "
            + "tesseract-ocr/tessdata_best). Usually it's a 'tessdata' subfolder of the Tesseract executables folder.",
            callback=on_tessdata_dir_change
        )
        self.add_file_selection_row(
            "START_MODEL",
            "Start model (optional)",
            "Model to use as a starting one and continue from it. Model files are the ones with '.traineddata' extension in your 'TessData folder'.\n"
            + "Only 'best' tessdata file version can be used for it. Please check Tesseract User Manual section \"Traineddata Files\" for details.",
            callback=on_start_model_change
        )
        self.add_folder_selection_row(
            "GROUND_TRUTH_DIR",
            "Input Ground Truth directory",
            "Directory containing line images (supported formats: "
            + ' '.join(SUPPORTED_IMAGE_FILES)
            + ") and corresponding transcription files (.gt.txt). Transcriptions must be single-line plain text and have the same name as the line image but "
            + "with the image extension replaced by .gt.txt.\n"
            + "The '.box' and '.lstmf' files will aslo be generated and saved here.\n\n"
            + "Note that if there are missing .gt.txt files you will be asked to input what should be recognized for each picture that is missing corresponding"
            + " .gt.txt file and your answer will be saved in a proper .gt.txt file.",
            callback=on_ground_truth_dir_change
        )
        self.add_folder_selection_row(
            "DATA_DIR",
            "Output data directory",
            "Data directory for output files, proto model, start model, etc.\n"
            + "It will be created if it doesn't exist. It is shown only for your reference.\n\n"
            + "This folder will also contain the new generated .traineddata file after successful training.",
            allow_change=False,
        )
        self.add_edit_box_row(
            "MODEL_NAME",
            "New language model name",
            "Name of the model to be built.",
        )
        self.add_folder_selection_row(
            "OUTPUT_DIR",
            "Training files output directory",
            "Output directory for generated files. It is a sub-folder of the output data directory.\n"
            + "It will be created if it doesn't exist already."
        )
        self.add_float_selection_row(
            "LEARNING_RATE",
            "Learning rate",
            "Weight factor for new deltas.\n\n"
            + "The original Tesstrain script uses value 0.0001 if there is a start model used, otherwise 0.002. Default: 0.001"
        )
        self.add_drop_down_selection_row(
            "LANG_TYPE",
            "Language Type",
            ["Default", "Indic", "RTL", "Custom"],
            "Language type for automatic settings for Norm mode, Recorder and the Box generation script."
        )
        self.add_drop_down_selection_row(
            "NORM_MODE",
            "Norm mode",
            ["Combine graphemes", "Split graphemes", "Pure unicode"],
            "Norm mode value is used by 'unicharset_extractor' where mode means:\n"
            + "1=combine graphemes (use for Latin and other simple scripts)\n"
            + "2=split graphemes (use for Indic/Khmer/Myanmar)\n"
            + "3=pure unicode (use for Arabic/Hebrew/Thai/Tibetan)\n"
            + "\nSelect 'Language Type':'Custom' to be able to modify this setting.",
        )
        self.add_checkbox_row(
            "PASS_THROUGH_RECORDER",
            "Pass through recorder",
            "Pass through recorder value is used by the 'combine_lang_model'. If set, the recoder is a simple pass-through of the unicharset. Otherwise, "
            + "potentially a compression of it by encoding Hangul in Jamos, decomposing multi-unicode symbols into sequences of unicodes, and encoding Han "
            + "using the data in the radical_table_data, which must be the content of the file: langdata/radical-stroke.txt. The file is downloaded "
            + "automatically by this script. (Default: false)\n"
            + "\nSelect 'Language Type':'Custom' to be able to modify this setting."
        )
        self.add_checkbox_row(
            "LANG_IS_RTL",
            "Language is RTL",
            "True if language being processed is written Right-To-Left (for example Arabic/Hebrew). (Default:false)\n"
            + "\nSelect 'Language Type':'Custom' to be able to modify this setting."
        )
        self.add_drop_down_selection_row(
            "GENERATE_BOX_SCRIPT",
            "Box generation script",
            ["generate_line_box.py", "generate_line_syllable_box.py", "generate_wordstr_box.py"],
            "Following scripts are available:\n"
            + "- 'generate_line_box.py': Creates tesseract box files for given line-image:text pairs.\n"
            + "- 'generate_line_syllable_box.py': Creates tesseract box files for given line-image:text pairs. Generates grapheme clusters. (Not the full "
            + "Unicode text segmentation algorithm, but probably good enough for Devanagari).\n"
            + "- 'generate_wordstr_box.py': Creates tesseract WordStr box files for given line-image:text pairs."
            + "\n\nYou need to select 'Language Type':'Custom' to be able to modify this setting."
        )
        self.add_drop_down_selection_row(
            "PSM",
            "Page segmentation mode (PSM)",
            [
                "Orientation and script detection (OSD) only",
                "Automatic page segmentation with OSD",
                "Automatic page segmentation, but no OSD, or OCR",
                "Fully automatic page segmentation, but no OSD",
                "Single column of text of variable sizes",
                "Single uniform block of vertically aligned text",
                "Single uniform block of text",
                "Single text line",
                "Single word",
                "Single word in a circle",
                "Single character",
                "Sparse text",
                "Sparse text with OSD",
                "Raw line",
            ],
            "Page segmentation mode (PSM) is used for creating '.lstmf' files. It sets Tesseract to only run a subset of layout analysis and assume a certain "
            + "form of image. The options are:\n"
            + "0 = Orientation and script detection (OSD) only.\n"
            + "1 = Automatic page segmentation with OSD.\n"
            + "2 = Automatic page segmentation, but no OSD, or OCR. (not implemented)\n"
            + "3 = Fully automatic page segmentation, but no OSD. (Default)\n"
            + "4 = Assume a single column of text of variable sizes.\n"
            + "5 = Assume a single uniform block of vertically aligned text.\n"
            + "6 = Assume a single uniform block of text.\n"
            + "7 = Treat the image as a single text line.\n"
            + "8 = Treat the image as a single word.\n"
            + "9 = Treat the image as a single word in a circle.\n"
            + "10 = Treat the image as a single character.\n"
            + "11 = Sparse text. Find as much text as possible in no particular order.\n"
            + "12 = Sparse text with OSD.\n"
            + "13 = Raw line. Treat the image as a single text line, bypassing hacks that are Tesseract-specific.\n\n"
            + "(Recommended training value: 13)"
        )
        self.add_slider_row(
            "RATIO_TRAIN",
            "Train/eval ratio %",
            "Ratio of train/eval training data. For example 0.9 means 90% of trainig data is used for training mechanism and the remaining 10% is used for "
            + "evaluations of current training results. (Default: 0.90)"
        )
        self.add_integer_row(
            "MAX_ITERATIONS",
            "Maximum iterations",
            "If set, exit after this many iterations.\n"
            "A negative value is interpreted as epochs: number of iterations will be based on amount of training data, where one Epoch means an entire "
            + "dataset is passed through the neural network once).\n"
            + "0 value is infinite iterations which means end only if 'Target error rate' condition will be met."
        )
        self.add_edit_box_row(
            "TARGET_ERROR_RATE",
            "Target error rate",
            "Expected final recognition error percentage. Finish training if the Character Error Rate (CER) gets below this value. It is the "
            + "'--target_error_rate' argument for 'lstmtraining'.\n\n"
            + "(Default: 0.01)"
        )

        self.current_parent = tab2

        self.add_checkbox_row(
            "DEBUG_MODE",
            "Debug mode",
            "If enabled after each command executed in the system shell there will be a message showed with command output, waiting for confirmation to "
            + "continue."
        )
        self.add_checkbox_row(
            "AUTO_CLEAN_OLD_DATA",
            "Automatically clean old training data",
            "When enabled old training data will be removed without confirmation when a new training is started",
        )
        self.add_checkbox_row(
            "AUTO_UPDATE_TESSDATA",
            "Automatically update TessData",
            "If enabled, when training finishes successfuly, TessData folder will be updated with the newly trained model without confirmation. This means the "
            + "new .traineddata file will be copied to the TessData folder. If the file already exist in TessData, it will be overwritten",
        )
        self.add_checkbox_row(
            "BEEP_END_TRAINING",
            "Notify the end of training with a beep",
            "When enabled a beep will sound at the end of the training.",
        )
        self.add_file_selection_row(
            "LAST_CHECKPOINT",
            "Last checkpoint file",
            "During the training Tesseract creates checkpoint files. If the file already exists it will be used to generate .traineddata from it. Checkpoint "
            + "files are saved within 'checkpoints' subfolder of the selected 'Training files output directory'.\n\n"
            + "You can use 'Generate' button to generate .traineddata from any existing .checkpoint file.",
        )
        self.add_file_selection_row(
            "PROTO_MODEL",
            "Proto model file",
            "Name of the proto model. It's an automatically generated file for starter traineddata with combined Dawgs/Unicharset/Recoder for language model. "
            + "Usually it is '<YOUR MODEL NAME>.traineddata' file within 'Training files output directory'.\n\n"
            + "Note that if you want to fine tune some existing model (for example English 'eng' model) you should use the 'Start model' option for that "
            + "purpose."
        )
        self.add_file_selection_row(
            "WORDLIST_FILE",
            "Wordlist file (optional)",
            "Optional Wordlist file for Dictionary dawg. Example: my_model_name.wordlist"
        )
        self.add_file_selection_row(
            "NUMBERS_FILE",
            "Numbers file (optional)",
            "Optional Numbers file for number patterns dawg. Example: my_model_name.numbers"
        )
        self.add_file_selection_row(
            "PUNC_FILE",
            "Punc file (optional)",
            "Optional Punc file for Punctuation dawg. Example: my_model_name.punc"
        )
        self.add_edit_box_row(
            "DEBUG_INTERVAL",
            "Debug interval",
            "How often to display the alignment. If non-zero, show visual debugging every this many iterations. It's the '--debug_interval' argument for the "
            + "'lstmtraining' executable. Default: 0",
        )
        self.add_edit_box_row(
            "NET_SPEC",
            "Network specification",
            "Default network specification: [1,36,0,1 Ct3,3,16 Mp3,3 Lfys48 Lfx96 Lrx96 Lfx192 O1c###].\n"
            + "'c###' will be automatically replaced with 'c<unichars_size>', where <unichars_size> value is generated by 'unicharset_extractor' and saved in "
            + "the first line of its generated 'unicharset' output file.\n\n"
            + "This field is available for modification and used only if no 'Start model' is chosen.",
        )
        self.add_edit_box_row(
            "RANDOM_SEED",
            "Random seed",
            "Random seed for shuffling of the training/eval data selection. (Default: 0)"
        )

        self.current_parent = self.root

        self.add_root_button("Start", start_training)
        self.add_root_button("Cleanup", clean_up)
        self.add_root_button("Preview", preview)
        self.add_root_button("Exit", exit)

        self.root.mainloop()


def on_bin_dir_change(new_dir):
    pass


def on_tessdata_dir_change(new_dir):
    pass


def on_start_model_change(new_dir):
    pass


def on_ground_truth_dir_change(new_dir):
    pass


def start_training():
    pass


def clean_up():
    pass


def preview():
    pass
