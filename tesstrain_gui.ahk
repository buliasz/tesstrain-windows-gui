; (C) Copyright 2021, Bartlomiej Uliasz
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

#include _tesstrain.ahki
#include _gt_txt_creator.ahki
#include _gui_backend.ahki
#include _recognition_preview.ahki

#NoTrayIcon
#SingleInstance Off
FileEncoding "UTF-8-RAW"

VERSION_NUMBER := "2.1"

if (!A_IsCompiled) {
	TraySetIcon(A_ScriptDir "\icon.ico",,true)
}

CONFIGURATION_FILE := A_ScriptDir "\tesstrain_gui.ini"

CONFIGURATION_VARIABLES_LIST := ["BIN_DIR", "DATA_DIR", "TESSDATA", "GROUND_TRUTH_DIR", "DEBUG_MODE", "MODEL_NAME", "OUTPUT_DIR", "WORDLIST_FILE", "NUMBERS_FILE", "PUNC_FILE", "START_MODEL", "LAST_CHECKPOINT", "PROTO_MODEL", "MAX_ITERATIONS", "DEBUG_INTERVAL", "LEARNING_RATE", "NET_SPEC", "LANG_TYPE", "NORM_MODE", "PASS_THROUGH_RECORDER", "LANG_IS_RTL", "GENERATE_BOX_SCRIPT", "PSM", "RANDOM_SEED", "RATIO_TRAIN", "TARGET_ERROR_RATE", "CREATE_BEST_TRAINEDDATA", "CREATE_FAST_TRAINEDDATA", "DELETE_BOX_FILES", "DELETE_LSTMF_FILES", "DELETE_MODEL_DIRECTORY", "AUTO_SAVE", "REQUIREMENTS_VERIFIED", "AUTO_CLEAN_OLD_DATA", "AUTO_UPDATE_TESSDATA"]

CREATE_BEST_TRAINEDDATA := true
CREATE_FAST_TRAINEDDATA := true
DELETE_BOX_FILES := false
DELETE_LSTMF_FILES := false
DELETE_MODEL_DIRECTORY := true
AUTO_SAVE := true
WRONG_INPUT_MAP := Map()
REQUIREMENTS_VERIFIED := false
AUTO_CLEAN_OLD_DATA := true
AUTO_UPDATE_TESSDATA := false

; Start GUI
TesstrainGui()

TesstrainGui() {
	global mainGui, BIN_DIR, DATA_DIR, TESSDATA, GROUND_TRUTH_DIR, DEBUG_MODE, MODEL_NAME, OUTPUT_DIR, WORDLIST_FILE, NUMBERS_FILE, PUNC_FILE, START_MODEL, LAST_CHECKPOINT, PROTO_MODEL, MAX_ITERATIONS, DEBUG_INTERVAL, LEARNING_RATE, NET_SPEC, LANG_TYPE, NORM_MODE, PASS_THROUGH_RECORDER, LANG_IS_RTL, GENERATE_BOX_SCRIPT, PSM, RANDOM_SEED, RATIO_TRAIN, TARGET_ERROR_RATE, BINARIES, CREATE_BEST_TRAINEDDATA, CREATE_FAST_TRAINEDDATA, REQUIREMENTS_VERIFIED

	static firstColumnWidth:=225, secondColumnWidth:=370, rowHeight:=19
	mainGui := ""

	LoadSettings()
	if (!REQUIREMENTS_VERIFIED) {
		VerifyRequirements()
		REQUIREMENTS_VERIFIED := true
	}

	CreateGui()

	CreateGui()	{
		mainGui := Gui("+OwnDialogs", "Tesstrain GUI v." VERSION_NUMBER)

		tabs := mainGui.Add("Tab3", , ["Main settings","Advanced"])

		; Main Settings TAB
		
		AddFolderSelection(
			"Tesseract executables folder",
			"BIN_DIR",
			"A path to Tesseract executable files containing 'tesseract', 'combine_tessdata', 'unicharset_extractor', 'merge_unicharsets', 'lstmtraining' and 'combine_lang_model' executables.",
			OnBinDirChange,
			,
			true
		)

		AddFolderSelection(
			"TessData folder (containing '.traineddata' files)",
			"TESSDATA",
			"Path to the '.traineddata' directory with traineddata suitable for training (for example from tesseract-ocr\tessdata_best). Usually it's a 'tessdata' subfolder of the Tesseract executables folder.",
			OnTessdataDirChange
		)

		modelList := GetStartModelList()
		if (!ArrayContains(modelList, START_MODEL)) {
			MsgBox("Couldn't find the selected 'Start model' in your 'TessData folder'. Selecting no start model.")
			START_MODEL := modelList[1]
		}
		AddDropDown(
			"Start model (optional)",
			modelList,
			"START_MODEL",
			"Model to use as a starting one and continue from it. Model files are the ones with '.traineddata' extension in your 'TessData folder'.`n"
				. "Only 'best' tessdata file version can be used for it. Please check Tesseract User Manual section `"Traineddata Files`" for details.",
			OnStartModelChange
		)

		AddFolderSelection(
			"Input Ground Truth directory",
			"GROUND_TRUTH_DIR",
			"Directory containing line images (supported formats: " ArrayJoin(SUPPORTED_IMAGE_FILES, ", ") ") and corresponding transcription files (.gt.txt). Transcriptions must be single-line plain text and have the same name as the line image but with the image extension replaced by .gt.txt.`n"
				. "The '.box' and '.lstmf' files will aslo be generated and saved here.`n`n"
				. "Note that if there are missing .gt.txt files you will be asked to input what should be recognized for each picture that is missing corresponding .gt.txt file and your answer will be saved in a proper .gt.txt file.",
			OnGroundTruthDirChange
		)
		AddFolderSelection(
			"Output data directory",
			"DATA_DIR",
			"Data directory for output files, proto model, start model, etc.`n"
				. "It will be created if doesn't exist. It is shown only for your reference.`n`n"
				. "This folder will also contain the new generated .traineddata file after successful training."
		)
		AddEditBox(
			"New language model name",
			"MODEL_NAME",
			"Name of the model to be built.",,
			OnModelNameChange
		)
		AddFolderSelection(
			"Training files output directory",
			"OUTPUT_DIR",
			"Output directory for generated files. It is a subfolder of the output data directory.`nIt will be created if doesn't exist.",,
			false
		)
		AddNumberSelection(
			"Learning rate",
			"LEARNING_RATE",
			"Weight factor for new deltas.`n`n"
				. "The original Tesstrain script uses value 0.0001 if there is a start model used, otherwise 0.002. Default: 0.001"
		)
		AddDropDown(
			"Language Type",
			["Default", "Indic", "RTL", "Custom"],
			"LANG_TYPE",
			"Language type for automatic settings for Norm mode, Recorder and the Box generation script",
			OnLanguateTypeChange
		)
		AddIntegerSelection(
			"Norm mode",
			"NORM_MODE",
			"Norm mode value is used by 'unicharset_extractor' where mode means:`n"
				. "1=combine graphemes (use for Latin and other simple scripts)`n"
				. "2=split graphemes (use for Indic/Khmer/Myanmar)`n"
				. "3=pure unicode (use for Arabic/Hebrew/Thai/Tibetan)"
				. "`n`nSelect 'Language Type':'Custom' to be able to modify this setting."
		)
		AddCheckbox(
			"Pass through recorder",
			"PASS_THROUGH_RECORDER",
			"Pass through recorder value is used by the 'combine_lang_model'. If set, the recoder is a simple pass-through of the unicharset. Otherwise, potentially a compression of it by encoding Hangul in Jamos, decomposing multi-unicode symbols into sequences of unicodes, and encoding Han using the data in the radical_table_data, which must be the content of the file: langdata/radical-stroke.txt. The file is downloaded automatically by this script. (Default: false)"
				. "`n`nSelect 'Language Type':'Custom' to be able to modify this setting."
		)
		AddCheckbox(
			"Language is RTL",
			"LANG_IS_RTL",
			"True if language being processed is written Right-To-Left (for example Arabic/Hebrew). (Default:false)"
				. "`n`nSelect 'Language Type':'Custom' to be able to modify this setting."
		)
		AddDropDown(
			"Box generation script",
			["generate_line_box.py", "generate_line_syllable_box.py", "generate_wordstr_box.py"],
			"GENERATE_BOX_SCRIPT",
			"Following scripts are available:`n"
				. "- 'generate_line_box.py': Creates tesseract box files for given line-image:text pairs.`n"
				. "- 'generate_line_syllable_box.py': Creates tesseract box files for given line-image:text pairs. Generates grapheme clusters. (Not the full Unicode text segmentation algorithm, but probably good enough for Devanagari).`n"
				. "- 'generate_wordstr_box.py': Creates tesseract WordStr box files for given line-image:text pairs."
				. "`n`nYou need to select 'Language Type':'Custom' to be able to modify this setting."
		)
		AddIntegerSelection(
			"Page segmentation mode (PSM)",
			"PSM",
			"Page segmentation mode (PSM) is used for creating '.lstmf' files. It sets Tesseract to only run a subset of layout analysis and assume a certain form of image. The options are:`n"
				. "0 = Orientation and script detection (OSD) only.`n"
				. "1 = Automatic page segmentation with OSD.`n"
				. "2 = Automatic page segmentation, but no OSD, or OCR. (not implemented)`n"
				. "3 = Fully automatic page segmentation, but no OSD. (Default)`n"
				. "4 = Assume a single column of text of variable sizes.`n"
				. "5 = Assume a single uniform block of vertically aligned text.`n"
				. "6 = Assume a single uniform block of text.`n"
				. "7 = Treat the image as a single text line.`n"
				. "8 = Treat the image as a single word.`n"
				. "9 = Treat the image as a single word in a circle.`n"
				. "10 = Treat the image as a single character.`n"
				. "11 = Sparse text. Find as much text as possible in no particular order.`n"
				. "12 = Sparse text with OSD.`n"
				. "13 = Raw line. Treat the image as a single text line, bypassing hacks that are Tesseract-specific.`n`n"
				. "(Recommended training value: 13)",
			0,
			13,
		)
		AddNumberSelection(
			"Train/eval ratio",
			"RATIO_TRAIN",
			"Ratio of train/eval training data. For example 0.9 means 90% of trainig data is used for training mechanism and the remaining 10% is used for evaluations of current training results. (Default: 0.90)"
		)
		AddIntegerSelection(
			"Maximum iterations",
			"MAX_ITERATIONS",
			"If set, exit after this many iterations. A negative value is interpreted as epochs (number of iterations will be based on amount of training data; one Epoch is when an entire dataset is passed through the neural network once). 0 means infinite iterations (end only if 'Target error rate' condition will be met)."
		)
		AddNumberSelection(
			"Target error rate",
			"TARGET_ERROR_RATE",
			"Expected final recognition error percentage. Stop training if the Character Error Rate (CER) gets below this value. It's the '--target_error_rate' argument for 'lstmtraining'.`n`n"
				. "(Default: 0.01)"
		)

		; Advanced Settings TAB
		
		tabs.UseTab("Advanced")

		AddCheckbox(
			"Debug mode",
			"DEBUG_MODE",
			"If enabled after each command executed in the system shell there will be a message showed with command output, waiting for confirmation to continue.",
			true
		)
		
		AddCheckbox(
			"Automatically clean old training data",
			"AUTO_CLEAN_OLD_DATA",
			"When enabled old training data will be removed without confirmation when a new training is started",
			false
		)

		AddCheckbox(
			"Automatically update TessData",
			"AUTO_UPDATE_TESSDATA",
			"If enabled, when training finishes successfuly, TessData folder will be updated with the newly trained model without confirmation. This means the new .traineddata file will be copied to the TessData folder. If the file already exist in TessData, it will be overwritten",
			false
		)

		AddFileSelection(
			"Last checkpoint file",
			"LAST_CHECKPOINT",
			"During the training Tesseract creates checkpoint files. If the file already exists it will be used to generate .traineddata from it. Checkpoint files are saved within 'checkpoints' subfolder of the selected 'Training files output directory'.`n`n"
				. "You can use 'Generate' button to generate .traineddata from any existing .checkpoint file.",,
			false
		)
		AddFileSelection(
			"Proto model file",
			"PROTO_MODEL",
			"Name of the proto model. It's an automatically generated file for starter traineddata with combined Dawgs/Unicharset/Recoder for language model. Usually it is '<YOUR MODEL NAME>.traineddata' file within 'Training files output directory'.`n`n"
				. "Note that if you want to fine tune some existing model (for example English 'eng' model) you should use the 'Start model' option for that purpose.",,
			false
		)

		AddFileSelection(
			"Wordlist file (optional)",
			"WORDLIST_FILE",
			"Optional Wordlist file for Dictionary dawg. Example: " MODEL_NAME ".wordlist"
		)
		AddFileSelection(
			"Numbers file (optional)",
			"NUMBERS_FILE",
			"Optional Numbers file for number patterns dawg. Example: " MODEL_NAME ".numbers"
		)
		AddFileSelection(
			"Punc file (optional)",
			"PUNC_FILE",
			"Optional Punc file for Punctuation dawg. Example: " MODEL_NAME ".punc"
		)
		AddIntegerSelection(
			"Debug interval",
			"DEBUG_INTERVAL",
			"How often to display the alignment. If non-zero, show visual debugging every this many iterations. It's the '--debug_interval' argument for the 'lstmtraining' executable. Default: 0",
			0
		)
		AddEditBox(
			"Network specification",
			"NET_SPEC",
			"Default network specification: [1,36,0,1 Ct3,3,16 Mp3,3 Lfys48 Lfx96 Lrx96 Lfx192 O1c###].`n"
				. "'c###' will be automatically replaced with 'c<unichars_size>', where <unichars_size> value is generated by 'unicharset_extractor' and saved in the first line of its generated 'unicharset' output file.`n`n"
				. "This field is available for modification and used only if no 'Start model' is chosen.",
			"[1,36,0,1 Ct3,3,16 Mp3,3 Lfys48 Lfx96 Lrx96 Lfx192 O1c###]"
		)
		AddIntegerSelection(
			"Random seed",
			"RANDOM_SEED",
			"Random seed for shuffling of the training/eval data selection. (Default: 0)"
		)

		AddButtonWithCheckboxes(
			"Clean generated files",
			"Clean",
			CleanModelData,
			Map(
				"Output Model", "DELETE_MODEL_DIRECTORY",
				"'.box' files", "DELETE_BOX_FILES",
				"'.lstmf' files", "DELETE_LSTMF_FILES",
			),
			"For currently selected model name deletes all the 'Training files output directory' content and/or all '.box' / '.lstmf' files inside the Ground Truth directory.`n"
				. "Usually you need only to remove 'Training files output directory' if you have a new input files to process. You can choose previously generated traineddata file as a `Start model`.",
		)

		; Main buttons
		tabs.UseTab()


		AddButton(
			"Ground Truth Preview",
			"Preview",
			"Shows image, 'gt.txt' value and current OCR result for all your Ground Truth images starting from the newest files.",
			PreviewRecognition,
			true,
		)

		AddButtonWithCheckboxes(
			"Generate 'best' and/or 'fast' traineddata",
			"Generate",
			GenerateTrainedData,
			Map(
				"best", "CREATE_BEST_TRAINEDDATA",
				"fast", "CREATE_FAST_TRAINEDDATA",
			),
			"Allows you to generate 'best' and/or 'fast' traineddata from any checkpoint file created during training process (including the final one). The default .traineddata file generated during the training process located inside your selected 'Training files output directory' is the 'best' version for the final checkpoint. Checkpoint file names include Character Error Rate (CER), which is the first part after model name. The best ones are with the lowest CER rate."
		)

		startBtn := mainGui.Add("Button", "default xs section +center", "Start &Training")
		startBtn.OnEvent("Click", StartTrainingCb)
		exitBtn := mainGui.Add("Button", "ys x+10 checked", "E&xit")
		exitBtn.OnEvent("Click", ExitGui)
		resetBtn := mainGui.Add("Button", "ys x+10 checked", "&Reload")
		resetBtn.OnEvent("Click", (*)=>(mainGui.Destroy(), TesstrainGui()))
		saveBtn := mainGui.Add("Button", "ys x+10 checked", "&Save settings")
		saveBtn.OnEvent("Click", (*)=>SaveSettings(true))
		autosaveChb := mainGui.Add("Checkbox", "ys hp 0x20 Checked" AUTO_SAVE " vAUTO_SAVE", "Save settings &automatically on 'Start Training'")
		autosaveChb.OnEvent("Click", SetCtrlNameGlobalToCtrlValue)

		OnBinDirChange(BIN_DIR, false)
		OnTessdataDirChange(TESSDATA, false)
		OnGroundTruthDirChange(GROUND_TRUTH_DIR, false)
		OnLanguateTypeChange()

		mainGui.Show()
	}

	; Controls closures for automated creation

	AddFolderSelection(title, targetVariableName, description, OnChange:="", isShowChangeButton:=true, skipXs:=false) {
		mainGui.Add("Text", "section " (skipXs ? "" : "xs ") "w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("Edit", "ys hp ReadOnly w" secondColumnWidth " v" targetVariableName, %targetVariableName%)
		if (isShowChangeButton) {
			binSelectBtn := mainGui.Add("Button", "ys hp", "Change")
			binSelectBtn.OnEvent("Click", FolderSelectCb)
		}
		AddDescription(description, title)

		FolderSelectCb(*) {
			folder := DirSelect("*" %targetVariableName%,, "Please choose: " title)
			if (folder) {
				guiCtrl.Text := folder
				%targetVariableName% := folder
				if (OnChange) {
					OnChange(folder)
				}
			}
		}
	}

	AddFileSelection(title, targetVariableName, description, OnChange:="", isShowChangeButton:=true) {
		mainGui.Add("Text", "section xs w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("Edit", "ys hp ReadOnly w" secondColumnWidth " v" targetVariableName, %targetVariableName%)
		if (isShowChangeButton) {
			binSelectBtn := mainGui.Add("Button", "ys hp", "Change")
			binSelectBtn.OnEvent("Click", FileSelectCb)
		}
		AddDescription(description, title)

		FileSelectCb(*) {
			selectedFile := FileSelect("*" %targetVariableName%,, "Please choose: " title)
			if (selectedFile) {
				guiCtrl.Text := selectedFile
				%targetVariableName% := selectedFile
				if (OnChange) {
					OnChange(selectedFile)
				}
			}
		}
	}

	AddCheckbox(title, targetVariableName, description, skipXs:=false) {
		chb := mainGui.Add("Checkbox", "section " (skipXs ? "" : "xs ") "0x20 w" firstColumnWidth + 23 " h" rowHeight " Checked" %targetVariableName% " v" targetVariableName, title)
		chb.OnEvent("Click", SetCtrlNameGlobalToCtrlValue)
		AddDescription(description, title)
	}

	AddButtonWithCheckboxes(title, buttonText, ButtonCallback, checkboxTextToVariableMap, description) {
		mainGui.Add("Text", "section xs w" firstColumnWidth " h" rowHeight " +0x200", title)

		btn := mainGui.Add("Button", "ys hp", buttonText)
		btn.OnEvent("Click", ButtonCallback)

		for (chbTxt, chbVar in checkboxTextToVariableMap) {
			chb := mainGui.Add("Checkbox", "ys hp Checked" %chbVar% " v" chbVar, chbTxt)
			chb.OnEvent("Click", SetCtrlNameGlobalToCtrlValue)
		}

		AddDescription(description, title)
	}

	AddEditBox(title, targetVariableName, description, defaultValue:="", OnChangeCallback:="") {
		mainGui.Add("Text", "section xs w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("Edit", "ys hp w" secondColumnWidth " v" targetVariableName, %targetVariableName%)
		guiCtrl.OnEvent("Change", SetCtrlNameGlobalToCtrlValue)
		if (OnChangeCallback) {
			guiCtrl.OnEvent("Change", OnChangeCallback)
		}
		AddDefaultButton(targetVariableName, defaultValue)
		AddDescription(description, title)
	}

	AddIntegerSelection(title, targetVariableName, description, minValue:=-2147483648, maxValue:=2147483647) {
		mainGui.Add("Text", "section xs w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("Edit", "ys hp Number v" targetVariableName)
		guiCtrl.OnEvent("Change", SetCtrlNameGlobalToCtrlValue)
		udCtrl := mainGui.Add("UpDown", "Range" minValue "-" maxValue, %targetVariableName%)
		AddDescription(description, title)
	}

	AddNumberSelection(title, targetVariableName, description) {
		mainGui.Add("Text", "section xs w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("Edit", "ys Number w" secondColumnWidth " hp v" targetVariableName, %targetVariableName%)
		guiCtrl.OnEvent("Change", SetCtrlNameGlobalToCtrlValue)
		AddDescription(description, title)
	}

	AddDropDown(title, optionList, targetVariableName, description, OnChange:="") {
		mainGui.Add("Text", "section xs w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("DropDownList", "ys hp w" secondColumnWidth " r10 Sort v" targetVariableName, optionList)
		guiCtrl.Choose(%targetVariableName%)
		AddDescription(description, title)
		guiCtrl.OnEvent("Change", SetCtrlNameGlobalToCtrlText)
		if (OnChange) {
			guiCtrl.OnEvent("Change", OnChange)
		}
	}

	AddButton(title, buttonText, description, OnClick, skipXs:=false) {
		mainGui.Add("Text", "section " (skipXs ? "" : "xs ") "w" firstColumnWidth " h" rowHeight " +0x200", title)
		guiCtrl := mainGui.Add("Button", "ys hp", buttonText)
		guiCtrl.OnEvent("Click", OnClick)
		AddDescription(description, title)
	}

	AddDescription(description, title) {
		descriptionBtn := mainGui.Add("Button", "ys hp", "?")
		descriptionBtn.OnEvent("Click", DescriptionBox)
		DescriptionBox(*) {
			mainGui.Opt("+OwnDialogs")  ; Force the user to dismiss the dialog before interacting with the main window.
			MsgBox(description, title)
		}
	}

	AddDefaultButton(varableName, defaultValue) {
		if (!defaultValue) {
			return
		}
		defaultBtn := mainGui.Add("Button", "ys hp", "Default")
		defaultBtn.OnEvent("Click", SetDefaultValue)
		SetDefaultValue(btnCtrl, *) {
			%varableName% := defaultValue
			btnCtrl.Gui[varableName].Value := defaultValue
		}
	}

	SetCtrlNameGlobalToCtrlValue(ctrlObj, *) {
		global
		%ctrlObj.Name% := ctrlObj.Value
	}

	SetCtrlNameGlobalToCtrlText(guiCtrl, *) {
		global
		%guiCtrl.Name% := guiCtrl.Text
	}

	; Updates value of a control and global variable to the provided one
	UpdateValue(globalName, newValue) {
		mainGui[globalName].Value := %globalName% := newValue
	}

	; Updates text value of a control and global variable to the provided one
	UpdateTextValue(globalName, newValue) {
		mainGui[globalName].Text := %globalName% := newValue
	}

	; CALLBACKS

	OnLanguateTypeChange(*) {
		mainGui["NORM_MODE"].Enabled := false
		mainGui["PASS_THROUGH_RECORDER"].Enabled := false
		mainGui["LANG_IS_RTL"].Enabled := false
		mainGui["GENERATE_BOX_SCRIPT"].Enabled := false

		if (LANG_TYPE == "Indic") {
			UpdateValue("NORM_MODE", 2)
			UpdateValue("PASS_THROUGH_RECORDER", true)
			UpdateValue("LANG_IS_RTL", false)
			UpdateTextValue("GENERATE_BOX_SCRIPT", "generate_wordstr_box.py")
		}
		else if (LANG_TYPE == "RTL") {
			UpdateValue("NORM_MODE", 3)
			UpdateValue("PASS_THROUGH_RECORDER", true)
			UpdateValue("LANG_IS_RTL", true)
			UpdateTextValue("GENERATE_BOX_SCRIPT", "generate_wordstr_box.py")
		}
		else if (LANG_TYPE == "Default") {
			UpdateValue("NORM_MODE", 2)
			UpdateValue("PASS_THROUGH_RECORDER", false)
			UpdateValue("LANG_IS_RTL", false)
			UpdateTextValue("GENERATE_BOX_SCRIPT", "generate_line_box.py")
		}
		else {
			mainGui["NORM_MODE"].Enabled := true
			mainGui["PASS_THROUGH_RECORDER"].Enabled := true
			mainGui["LANG_IS_RTL"].Enabled := true
			mainGui["GENERATE_BOX_SCRIPT"].Enabled := true
		}
	}

	OnModelNameChange(*) {
		UpdateValue("OUTPUT_DIR", DATA_DIR "\" MODEL_NAME)
		UpdateValue("LAST_CHECKPOINT", OUTPUT_DIR "\checkpoints\" MODEL_NAME "_checkpoint")
		UpdateValue("PROTO_MODEL", OUTPUT_DIR "\" MODEL_NAME ".traineddata")
	}

	OnBinDirChange(newBinDir, showErrors:=true) {
		static binariesList := ["tesseract", "combine_tessdata", "unicharset_extractor", "merge_unicharsets", "lstmtraining", "combine_lang_model"]

		mainGui.Opt("+OwnDialogs")  ; Force the user to dismiss the dialog before interacting with the main window.

		errored := false

		for binaryName in BINARIES {
			foundFiles := FindAllFiles(BIN_DIR "\*" binaryName ".exe")
			if (foundFiles.Length == 0) {
				foundFiles := FindAllFiles(BIN_DIR "\*." binaryName "-master.exe")
			}
			if (foundFiles.Length == 0) {
				if (showErrors) {
					MsgBox("Error: Couldn't find any '" binaryName "' executable in the selected directory.",, "Iconx")
				}
				errored := true
				break
			} else if (foundFiles.Length > 1) {
				if (showErrors) {
					MsgBox("Error: Multiple binaries found matching criteria: '*" binaryName "*.exe':`n" ArrayJoin(foundFiles, "`n"),, "Iconx")
				}
				errored := true
				break
			} else {
				BINARIES[binaryName] := foundFiles[1]
			}
		}

		if (errored) {
			mainGui["BIN_DIR"].SetFont("cRed bold")
			WRONG_INPUT_MAP["BIN_DIR"] := "Wrong 'Tesseract executables folder'"
		}
		else {
			mainGui["BIN_DIR"].SetFont("cDefault norm")
			MapSafeDelete(WRONG_INPUT_MAP, "BIN_DIR")

			newTessdataDir := newBinDir "\tessdata"
			if (TESSDATA != newTessdataDir && DirExist(newTessdataDir)) {
				if (YesNoConfirmation("Found 'tessdata' subfolder inside selected executables folder. Do you want to set it as 'TessData folder'?")) {
					UpdateValue("TESSDATA", newTessdataDir)
					OnTessdataDirChange(newTessdataDir)
				}
			}
		}
	}

	OnTessdataDirChange(newTessdataDir, showErrors:=true) {
		mainGui.Opt("+OwnDialogs")  ; Force the user to dismiss the dialog before interacting with the main window.

		if (FindAllFiles(newTessdataDir "\*.traineddata").Length == 0) {
			if (showErrors) {
				MsgBox("The selected folder doesn't contain any .traineddata files. Please select another one.",, "Iconx")
			}
			mainGui["TESSDATA"].SetFont("cRed bold")
			WRONG_INPUT_MAP["TESSDATA"] := "Wrong 'TessData folder'"
		}
		else {
			mainGui["TESSDATA"].SetFont("cDefault norm")
			MapSafeDelete(WRONG_INPUT_MAP, "TESSDATA")

			UpdateStartModel()
		}
	}

	OnGroundTruthDirChange(newGroundTruthDir, showErrors:=true) {
		mainGui.Opt("+OwnDialogs")  ; Force the user to dismiss the dialog before interacting with the main window.

		for (imageExtension in SUPPORTED_IMAGE_FILES) {
			if (FindAllFiles(newGroundTruthDir "\*" imageExtension).Length > 0) {
				mainGui["GROUND_TRUTH_DIR"].SetFont("cDefault norm")
				MapSafeDelete(WRONG_INPUT_MAP, "GROUND_TRUTH_DIR")
				return
			}
		}
		if (showErrors) {
			MsgBox("No line images found in your selected Ground Truth directory. Please make sure to copy line image files that would be used for training before starting the training.`nSupported formats: " ArrayJoin(SUPPORTED_IMAGE_FILES, ", "),, "Iconx")
		}
		mainGui["GROUND_TRUTH_DIR"].SetFont("cRed bold")
		WRONG_INPUT_MAP["GROUND_TRUTH_DIR"] := "No line image files in the 'Ground Truth folder'"
	}

	OnStartModelChange(*) {
		mainGui["NET_SPEC"].Enabled := (START_MODEL == "")
	}

	UpdateStartModel() {
		mainGui.Opt("+OwnDialogs")  ; Force the user to dismiss the dialog before interacting with the main window.

		modelList := GetStartModelList()
		mainGui["START_MODEL"].Delete()
		mainGui["START_MODEL"].Add(modelList)
		if (!ArrayContains(modelList, START_MODEL)) {
			MsgBox("Couldn't find the selected 'Start model' in your 'TessData folder'. Selecting no start model.")
			START_MODEL := modelList[1]
		}
		mainGui["START_MODEL"].Choose(START_MODEL)
		OnStartModelChange()
	}
}
