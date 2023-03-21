import tkinter as tk

CONFIGURATION_FILE = "tesstrain_gui.ini"

Config = {}

VALUE_VALIDATORS = {
    "TARGET_ERROR_RATE": lambda a: is_number(a) and 0 <= a <= 100,
    "RATIO_TRAIN": lambda a: is_number(a) and 0 < a < 1,
    "LEARNING_RATE": lambda a: is_number(a) and 0 < a <= 1,
    "MAX_ITERATIONS": lambda a: is_integer(a),
}


def verify_requirements():
    pass


DEFAULTS = {
    "NET_SPEC": "[1,36,0,1 Ct3,3,16 Mp3,3 Lfys48 Lfx96 Lrx96 Lfx192 O1c###]",
    "BIN_DIR": "",
    "DATA_DIR": "",
    "TESSDATA": "",
    "GROUND_TRUTH_DIR": "",
    "DEBUG_MODE": "",
    "MODEL_NAME": "",
    "OUTPUT_DIR": "",
    "WORDLIST_FILE": "",
    "NUMBERS_FILE": "",
    "PUNC_FILE": "",
    "START_MODEL": "",
    "LAST_CHECKPOINT": "",
    "PROTO_MODEL": "",
    "MAX_ITERATIONS": "",
    "DEBUG_INTERVAL": "",
    "LEARNING_RATE": "",
    "LANG_TYPE": "",
    "NORM_MODE": "",
    "PASS_THROUGH_RECORDER": "",
    "LANG_IS_RTL": "",
    "GENERATE_BOX_SCRIPT": "",
    "PSM": "",
    "RANDOM_SEED": "",
    "RATIO_TRAIN": "",
    "TARGET_ERROR_RATE": "",
    "CREATE_BEST_TRAINEDDATA": "",
    "CREATE_FAST_TRAINEDDATA": "",
    "DELETE_BOX_FILES": "",
    "DELETE_LSTMF_FILES": "",
    "DELETE_MODEL_DIRECTORY": "",
    "AUTO_SAVE": "",
    "REQUIREMENTS_VERIFIED": "",
    "AUTO_CLEAN_OLD_DATA": "",
    "AUTO_UPDATE_TESSDATA": "",
    "BEEP_END_TRAINING": "",
}


def load_config():
    Config["BIN_DIR"] = tk.StringVar()
    Config["DATA_DIR"] = tk.StringVar()
    Config["TESSDATA"] = tk.StringVar()
    Config["GROUND_TRUTH_DIR"] = tk.StringVar()
    Config["DEBUG_MODE"] = tk.StringVar()
    Config["MODEL_NAME"] = tk.StringVar()
    Config["OUTPUT_DIR"] = tk.StringVar()
    Config["WORDLIST_FILE"] = tk.StringVar()
    Config["NUMBERS_FILE"] = tk.StringVar()
    Config["PUNC_FILE"] = tk.StringVar()
    Config["START_MODEL"] = tk.StringVar()
    Config["LAST_CHECKPOINT"] = tk.StringVar()
    Config["PROTO_MODEL"] = tk.StringVar()
    Config["MAX_ITERATIONS"] = tk.StringVar()
    Config["DEBUG_INTERVAL"] = tk.StringVar()
    Config["LEARNING_RATE"] = tk.StringVar()
    Config["NET_SPEC"] = tk.StringVar()
    Config["LANG_TYPE"] = tk.StringVar()
    Config["NORM_MODE"] = tk.StringVar()
    Config["PASS_THROUGH_RECORDER"] = tk.BooleanVar()
    Config["LANG_IS_RTL"] = tk.BooleanVar()
    Config["GENERATE_BOX_SCRIPT"] = tk.StringVar()
    Config["PSM"] = tk.StringVar(value="")
    Config["RANDOM_SEED"] = tk.StringVar()
    Config["RATIO_TRAIN"] = tk.IntVar(value=90)
    Config["TARGET_ERROR_RATE"] = tk.StringVar()
    Config["CREATE_BEST_TRAINEDDATA"] = tk.BooleanVar(value=True)
    Config["CREATE_FAST_TRAINEDDATA"] = tk.BooleanVar(value=True)
    Config["DELETE_BOX_FILES"] = tk.BooleanVar(value=False)
    Config["DELETE_LSTMF_FILES"] = tk.BooleanVar(value=False)
    Config["DELETE_MODEL_DIRECTORY"] = tk.BooleanVar(value=True)
    Config["AUTO_SAVE"] = tk.BooleanVar(value=True)
    Config["REQUIREMENTS_VERIFIED"] = tk.BooleanVar(value=False)
    Config["AUTO_CLEAN_OLD_DATA"] = tk.BooleanVar(value=True)
    Config["AUTO_UPDATE_TESSDATA"] = tk.BooleanVar(value=False)
    Config["BEEP_END_TRAINING"] = tk.BooleanVar(value=True)

    # not saved
    Config["WRONG_INPUT_MAP"] = {}
    Config["SHUTDOWN_AFTER_TRAINING_COMPLETION"] = tk.BooleanVar(value=False)


def is_number(a):
    # TODO
    return True


def is_integer(a):
    return True
