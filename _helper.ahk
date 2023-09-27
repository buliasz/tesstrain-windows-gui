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

#include _console.ahk
#include _quick_sort.ahk

SetGlobal(varName, varValue) {
	global
	%varName% := varValue
}

; ----------------
; STRING FUNCTIONS
; ----------------

StrCutEnd(text, numberOfCharacters) {
	return SubStr(text, 1, -numberOfCharacters)
}

StrRCutTo(text, cutStartStr) {
	cutIndex := InStr(text, cutStartStr,,, -1)
	if (!cutIndex) {
		return text
	}
	return SubStr(text, cutIndex + StrLen(cutStartStr))
}

StrRCutFrom(text, cutStartStr) {
	cutIndex := InStr(text, cutStartStr,,, -1)
	if (!cutIndex) {
		return text
	}
	return SubStr(text, 1, cutIndex - 1)
}

StrEndsWith(text, ending) {
	return SubStr(text, -StrLen(ending)) == ending
}


; ---------------
; ARRAY FUNCTIONS
; ---------------

ArrayContains(_array, itemToFind) {
	for (item in _array) {
		if (item == itemToFind) {
			return true
		}
	}
	return false
}

ArrayTransform(arr, method, argument) {
	ret := []
	for (element in arr) {
		ret.Push(method(element, argument))
	}
	return ret
}

ArrayForEach(arr, Callback) {
	for (item in arr) {
		Callback(item)
	}
}

ArrayToString(arr, joinWith:=" ") {
	ret := ""
	for element in arr {
		if (A_Index > 1) {
			ret .= joinWith element
		} else {
			ret .= element
		}
	}
	return ret
}

ArrayHead(arr, headLength) {
	headArray := []
	remaining := headLength

	for (item in arr) {
		if (remaining <= 0) {
			break
		}
		headArray.Push(item)
		remaining -= 1
	}

	return headArray
}

ArrayTail(arr, tailLength) {
	tailArray := []
	if (arr.Length <= tailLength) {
		return arr
	}

	skip := arr.Length - tailLength
	for (item in arr) {
		if (skip <= 0) {
			tailArray.Push(item)
		} else {
			skip -= 1
		}
	}

	return tailArray
}

ArrayPushAll(source, target) {
	for (item in source) {
		target.Push(item)
	}
}

ArraySort(arr, func:="") {
	if (arr.Length == 0) {
		return []
	}
	if (!func && !IsNumber(arr[1])) {
		func := StrCompare
	}
	return QuickSort(arr, func)
}


;----------------------
; MAP FUNCTIONS
;----------------------

MapSafeDelete(_map, _key) {
	if (_map.Has(_key)) {
		_map.Delete(_key)
	}
}


;----------------------
; FILE SYSTEM FUNCTIONS
;----------------------

FileSave(fileName, content) {
	myFile := FileOpen(fileName, "w")
	myFile.Write(content)
	myFile.Close()
}

FindAllFiles(pattern) {
	filesFound := []
	loop Files, pattern {
		filesFound.Push(A_LoopFileFullPath)
	}
	return filesFound
}

FindAllFilesExtended(pattern) {
	filesFound := []
	loop Files, pattern {
		filesFound.Push({path: A_LoopFileFullPath, modified: A_LoopFileTimeModified})
	}
	return filesFound
}

FindNewestFile(pattern) {
	fileFound := ""
	modified := ""
	loop Files, pattern {
		if (StrCompare(A_LoopFileTimeModified, modified) > 0) {
			fileFound := A_LoopFileFullPath
			modified := A_LoopFileTimeModified
		}
	}
	return fileFound
}

FileGetFirstLine(filePath) {
	return GetFileLine(filePath, 1)
}

GetFileLine(filePath, lineNumber) {
	savedLine := ""
	loop read, filePath {
		if (A_Index == lineNumber) {
			savedLine := A_LoopReadLine  ; When loop finishes, this will hold the last line.
			break
		}
	} else {
		throw Error("File '" filePath "' not found")
	}

	return savedLine
}

; Removes path leaving only file name with extension
; Alternatively 'SplitPath' AHK command may be used
FileGetName(filePathWithName) {
	return StrRCutTo(filePathWithName, "\")
}

IsFileOlder(file1, file2) {
	return StrCompare(FileGetTime(file1), FileGetTime(file2)) < 0
}

IsFileNewer(file1, file2) {
	return StrCompare(FileGetTime(file1), FileGetTime(file2)) > 0
}

; ----------------------
; OTHER HELPER FUNCTIONS
; ----------------------

GetNonEmptyLines(filePath) {
	lines := []
	loop read, filePath {
		line := Trim(A_LoopReadLine)
		if (line != "") {
			lines.Push(line)
		}
	}
	return lines
}

CmdLogAppend(text) {
	FileAppend text, "command.log"
}

OcrImageFile(imageFullPath, lang:="", tessdataDir:="", pis:=0, local_psm:="") {
	if (!tessdataDir) {
		tessdataDir := TESSDATA
	}
	outputFile := DATA_DIR "\preview.out"
	ocrOutput := ExecuteCommand("`"" BINARIES["tesseract"] "`" `"" imageFullPath "`" -"
		. (lang ? " -l " lang : "")
		. " --psm " (local_psm || PSM) " -c preserve_interword_spaces=" pis " -c page_separator= --tessdata-dir `"" tessdataDir "`" >`"" outputFile "`"", 2)
	return Trim(FileRead(outputFile), "`t`n`r ")
}

ProgressStatusGui(newStatus:="", parentGui:="", windowTitle:="Training progress") {
	static lastStatus:="", statusGui:="", savedParentGui:="", bcer:={}, generateBtn:={}
	global SHUTDOWN_AFTER_TRAINING_COMPLETION, StatusUpdate

	; Remove StatusGui if empty arguments and resets to default status function
	if (!newStatus && statusGui) {
		MonitorCheckpoints(false)
		if (savedParentGui) {
			savedParentGui.Show()
		}
		bcer := generateBtn := {}	; prevents error if there is an ongoing CheckCheckpoints timer
		statusGui.Destroy()
		lastStatus := statusGui := savedParentGui := ""
		StatusUpdate := DEFAULT_STATUS_FUNCTION
		return
	}

	if (!statusGui) {
		statusGui := Gui("-Resize +AlwaysOnTop -SysMenu +OwnDialogs", windowTitle)
		if (parentGui) {
			parentGui.Hide()
			savedParentGui := parentGui
		}
		if (windowTitle == "Training progress") {
			statusGui.Add("Text", "section xm w115", "Best checkpoint BCER")
			bcer := statusGui.Add("Text", "ys w50", "-")
			bcer.SetFont("bold")
			generateBtn := statusGui.Add("Button", "ys w240", "&Generate model from currently best checkpoint")
			generateBtn.OnEvent("Click", GenerateTraineddata)
			generateBtn.Enabled := false
			MonitorCheckpoints(true)
			shutdownChb := statusGui.Add("Checkbox", "xs hp 0x20 Checked" SHUTDOWN_AFTER_TRAINING_COMPLETION, "Shutdown computer after successfully completed (automatically updates TessData)")
			shutdownChb.OnEvent("Click", (ctrlObj,*)=>SHUTDOWN_AFTER_TRAINING_COMPLETION:=ctrlObj.Value)
		}
	}

	if (lastStatus) {
		lastStatus.Text := "Done"
	}
	statusGui.Add("Text", "section xm w360", newStatus)
	lastStatus := statusGui.Add("Text", "ys w40", "...")
	statusGui.Show("AutoSize")
	
	return

	MonitorCheckpoints(isEnable) {
		if (isEnable) {
			SetTimer CheckCheckpoints, 2000
		} else {
			SetTimer CheckCheckpoints, 0
		}
	}

	CheckCheckpoints() {
		if ((name:=FindNewestFile(OUTPUT_DIR "\checkpoints\" MODEL_NAME "_*.checkpoint")) && statusGui) {
			bcer.Text := GetBcerFromName(name)
			generateBtn.Enabled := true
		}
	}
	
	GenerateTraineddata(*) {
		checkpointFile := FindNewestFile(OUTPUT_DIR "\checkpoints\" MODEL_NAME "_*.checkpoint")
		Checkpoint2Traineddata(checkpointFile, DATA_DIR "\" MODEL_NAME ".traineddata", false)
		if (UpdateModelFileInTessdata()) {
			MsgBox("New model successfully generated and/or updated", PROGRAM_TITLE)
		}
	}
}

GetBcerFromName(name) {
	bcer := name
	bcer := StrRCutFrom(bcer, "_")
	bcer := StrRCutFrom(bcer, "_")
	bcer := StrRCutTo(bcer, "_")
	if (StrLen(bcer) > 5) {
		bcer := SubStr(bcer, 1, 5)
	}
	return bcer
}

VerifyRequirements() {
	ProgressStatusGui("Starting up",, PROGRAM_TITLE)

	VerifyPythonDependencies()

	ProgressStatusGui()
	return true
}

VerifyPythonDependencies() {
	ProgressStatusGui("Verifying installed Python version")
	try {
		version := ExecuteCommand("python --version")
		PYTHON_EXE := "python"
	} catch Error as ePython {
		try {
			version := ExecuteCommand("python3 --version")
			PYTHON_EXE := "python3"
		} catch Error as ePython3 {
			ErrorBox("Executing 'python' command returned error: " ePython.Message "`n`n"
				. "Executing 'python3' command returned error: " ePython3.Message "`n`n"
				. "Please make sure that you have a Python 3.x installed and that "
				. "'python.exe' or 'python3.exe' executable file directory is in your PATH environment variable.")
			ExitApp()
		}
	}

	versionStr := StrRCutTo(Trim(version.StdOut, "`t`n`r "), " ")
	versionArray := StrSplit(versionStr, ".")
	if (versionArray.Length < 1 || !IsInteger(versionArray[1]) || versionArray[1] < 3) {
		ErrorBox("Wrong Python version. Returned version: '" versionStr "'. Please install Python version 3 or above.")
		ExitApp()
	}

	ProgressStatusGui("Verifying/installing required Python modules")

	installCommand := PYTHON_EXE " -m pip install --no-input --disable-pip-version-check -r `"" TESSTRAIN_DIR "\requirements.txt`""
	try {
		ExecuteCommand(installCommand)
	} catch Error as e {
		if (YesNoConfirmation("Could not install required Python modules. Probably you don't have required privilages.`n"
			. "Do you want me to try again as Administrator?")) {
			ExecuteCommand(installCommand,, true)
			ExecuteCommand()
		} else {
			ErrorBox("Error installing required Python modules.`n" e.Message)
			ExitApp()
		}
	}
}

AotBox(message) {
	MsgBox(message, PROGRAM_TITLE, 0x40000)
}

YesNoConfirmation(message) {
	return MsgBox(message, PROGRAM_TITLE, "YesNo Icon? 0x40000") == "Yes"
}

ErrorBox(message) {
	return MsgBox(message, PROGRAM_TITLE, "Icon! 0x40000")
}

NotAllowedBox(message) {
	return MsgBox(message, PROGRAM_TITLE, "IconX 0x40000")
}

OnError MyErrorFunction
MyErrorFunction(_exception, _mode) {
    ErrorBox(DescribeException(_exception) "`nMode: " _mode)
    ExitApp	; It's an unhandled exception. We want to Shutdown the app.
}

DescribeException(e) {
	extra := e.HasProp("Extra") ? e.Extra : ""
	return "Exception: " e.Message " in " e.What " at " e.File ":" e.Line
		.  (extra ? "`nAdditional information (e.Extra):`n" extra : "")  "`n`n"
		. CallStack(2)

	CallStack(startOffset:=0, maxLevels:="") {
		if (A_IsCompiled) {
			return
		}

		ret := ""
		indent := "`t"
		loop {
			if (maxLevels && A_Index > maxLevels) {
				break
			}
			offset := -(A_Index + startOffset)
			e := Error(".", offset)
			if (e.What == offset) {
				break
			}
			fileName := ""
			SplitPath e.file, &fileName
			ret .= "[" (offset + startOffset) "]" fileName "(" e.Line "):`n"
					. indent Trim(GetFileLine(e.file, e.line)) "`n"
			ret .= "`t=> " e.What "`n"
		}

		return ret
	}
}

DisableSystemStandby(shouldDisable) {
	static oldState:=0
	newState := shouldDisable ? 0x80000001 : 0x80000000
	if (newState != oldState) {
		DllCall("SetThreadExecutionState", "UInt", newState)
		oldState := newState
	}
}

TemporaryTooltip(message, seconds) {
	ToolTip(message)
	SetTimer(Tooltip, -1000 * seconds)
}
