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

; Allows preview of OCR recognition after training is done

PreviewRecognition(btnCtrl, *) {
	closeRequest := false
	ocrInProgress := false
	searchEnabled:=false

	col1Width := 120
	col2Width := 680
	tessdataDirForOcr := DATA_DIR
	modelNameForOcr := MODEL_NAME
	ignoreSpaces := false
	preserveSpaces := false
	recognizedValue := expectedValue := ""
	previewPsm := PSM

	if (!_CheckGeneratedModelExistence()) {
		message := "There is no newly generated model of name '" MODEL_NAME "' inside the '" DATA_DIR "' folder.`n"
		if (START_MODEL) {
			if (YesNoConfirmation(message "Do you want to use Start Model instead for this preview?")) {
				tessdataDirForOcr := TESSDATA
				modelNameForOcr := START_MODEL
			} else {
				return
			}
		} else {
			NotAllowedBox(message "Please execute training first or select a Start Model.")
			return
		}
	}

	imageList := []
	for fileExtension in SUPPORTED_IMAGE_FILES {
		ArrayPushAll(FindAllFilesExtended(GROUND_TRUTH_DIR "\*" fileExtension), imageList)
	}

	if (imageList.Length == 0) {
		NotAllowedBox("No supported images found in your Ground Truth directory")
		return
	}

	imageList := ArraySort(imageList, (a,b)=>b.modified-a.modified) 	; Sort by modificaton date descending
	imageListPosition := 1

	; Create GUI

	previewGui := Gui("-Resize -DPIScale +Owner" btnCtrl.Gui.Hwnd, "Trained Image")

	imageFullPath := imageList[imageListPosition].path
	previewGui.Add("Text", "section xm w" col1Width, "Processed image:")
	imagePathCtrl := previewGui.Add("Edit", "ys w" col2Width " r1 +ReadOnly vImagePath", imageFullPath)

	ocrResultLabelCtrl := previewGui.Add("Text", "section xm w" col1Width, "Recongized value:")
	previewGui.SetFont("s15 w678 cGreen")
	ocrResultCtrl := previewGui.Add("Edit", "ys w" col2Width " r2 +ReadOnly vOcrResult", "")
	previewGui.SetFont()

	gtTxtLabelCtrl := previewGui.Add("Text", "section xm h35 w" col1Width, "Value from .gt.txt file:")
	previewGui.SetFont("cBlue s15 w678")
	gtTxtCtrl := previewGui.Add("Edit", "ys w" col2Width " r2 +ReadOnly vGtTxtValue", "")
	previewGui.SetFont()

	previousButton := previewGui.Add("Button", "xm section default Disabled" (imageListPosition == 1), "&Previous")
	previousButton.OnEvent("Click", _ShowPreviousImage)

	nextButton := previewGui.Add("Button", "ys Disabled" (imageListPosition == imageList.Length), "&Next")
	nextButton.OnEvent("Click", _ShowNextImage)

	searchWrongButton := previewGui.Add("Button", "ys", "Find next &Wrong OCR")
	searchWrongButton.OnEvent("Click", _FindNextWrongOcr)

	stopSearchButton := previewGui.Add("Button", "xp yp Hidden", "&Stop searching")
	stopSearchButton.OnEvent("Click", _StopSearchCallback)

	deleteButton := previewGui.Add("Button", "ys", "&Delete")
	deleteButton.OnEvent("Click", _DeleteFilesCallback)

	gotoButton := previewGui.Add("Button", "ys", "&Go to")
	gotoButton.OnEvent("Click", _GotoImagePosition)
	gotoPageNumber := previewGui.Add("Edit", "ys w60 Number")
	gotoPageNumber.OnEvent("Change", _GotoChange)
	previewGui.Add("UpDown", "Range1-" imageList.Length, 1)

	previewGui.Add("Text", "ys hp +0x200", "PSM")
	psmInputCtrl := previewGui.Add("Edit", "ys w50 Number")
	psmInputCtrl.OnEvent("Change", _PsmChange)
	previewGui.Add("UpDown", "Range1-13", previewPsm)

	preserveSpacesCtrl := previewGui.Add("Checkbox", "ys Checked" preserveSpaces, "Preserve inter-word spaces")
	preserveSpacesCtrl.OnEvent("Click", (ctrlObj, *)=>(preserveSpaces:=ctrlObj.Value, _RefreshGui()))

	ignoreSpacesCtrl := previewGui.Add("Checkbox", "xp Checked" ignoreSpaces, "Ignore spaces")
	ignoreSpacesCtrl.OnEvent("Click", (ctrlObj,*)=>(ignoreSpaces:=ctrlObj.Value, preserveSpacesCtrl.Enabled:=!ignoreSpaces, _RefreshGui()))

	picCtrl := previewGui.Add("Picture", "xm w" (col1Width + col2Width) " h-1", imageFullPath)

	progressStatus := previewGui.Add("StatusBar",, "Preview OCR for image 1 / " imageList.Length)
	previewGui.Title := PROGRAM_TITLE " - Ground Truth Preview"

	previewGui.Show("AutoSize")  ; Resize the window to match the picture size.
	previewGui.OnEvent("Close", _CloseCb)
	previewGui.OnEvent("Escape", _CloseCb)
	btnCtrl.Gui.Opt("+Disabled")
	_RefreshGui()

	GetGtTxtContent() {
		gtTxtPath := RemoveImageExtension(imageFullPath) ".gt.txt"
		if (FileExist(gtTxtPath)) {
			return FileGetFirstLine(gtTxtPath)
		} else {
			return "<no .gt.txt file>"
		}
	}

	_RefreshGui() {
		if (closeRequest) {
			return
		}
		ocrInProgress := true

		; prepare values
		imageFullPath := imageList[imageListPosition].path
		recognizedValue := OcrImageFile(imageFullPath, modelNameForOcr, tessdataDirForOcr, preserveSpaces, previewPsm)
		expectedValue := GetGtTxtContent()

		; update displayed values
		imagePathCtrl.Text := imageFullPath
		gtTxtCtrl.Text := expectedValue
		ocrResultCtrl.Text := recognizedValue
		ocrResultCtrl.SetFont("bold " (_CompareResults(recognizedValue, expectedValue) ? "cGreen" : "cRed"))
		progressStatus.SetText("Preview OCR for image " imageListPosition " / " imageList.Length)
		picCtrl.Value := "*w" (col1Width + col2Width) " *h-1 " imageFullPath  ; Load the image.
		if (!searchEnabled) {
			nextButton.Enabled := (imageListPosition < imageList.Length)
			previousButton.Enabled := (imageListPosition > 1)
		}
		previewGui.Show("AutoSize")  ; Resize the window to match the picture size.
		imagePathCtrl.Focus()

		ocrInProgress := false
		if (closeRequest) {
			_CloseCb()
		}
	}

	_DeleteFilesCallback(*) {
		if (!YesNoConfirmation("Do you want to delete current image with corresponding .gt.txt, .lstmf and .box files?")) {
			return
		}
		imageFullPath := imageList[imageListPosition].path
		FileDelete(imageFullPath)

		gtTxtPath := RemoveImageExtension(imageFullPath) ".gt.txt"
		if (FileExist(gtTxtPath)) {
			FileDelete(gtTxtPath)
		}

		lstmfPath := RemoveImageExtension(imageFullPath) ".lstmf"
		if (FileExist(lstmfPath)) {
			FileDelete(lstmfPath)
		}

		boxPath := RemoveImageExtension(imageFullPath) ".box"
		if (FileExist(boxPath)) {
			FileDelete(boxPath)
		}

		imageList.RemoveAt(imageListPosition)
		_RefreshGui()
	}

	_FindNextWrongOcr(searchCtrl, *) {
		_ReplaceControl(searchWrongButton, stopSearchButton)
		previousButton.Enabled := false
		nextButton.Enabled := false

		searchEnabled := true
		loop {
			_ShowNextImage()
		} until !searchEnabled || closeRequest || imageListPosition == imageList.Length || !_CompareResults(recognizedValue, expectedValue)
		SoundBeep 1800, 100
		if (imageListPosition == imageList.Length) {
			AotBox("No more images")
		}
		searchEnabled := false

		if (closeRequest) {
			_CloseCb()
		} else {
			_ReplaceControl(stopSearchButton, searchWrongButton)
			previousButton.Enabled := true
			nextButton.Enabled := true
		}
	}

	_ReplaceControl(controlToReplace, newControl) {
		if (closeRequest) {
			return
		}
		controlToReplace.GetPos(&x, &y, &w, &h)
		controlToReplace.Visible := false
		newControl.Visible := true
		newControl.Move(x, y, w, h)
	}

	_StopSearchCallback(stopCtrl, *) {
		searchEnabled := false
	}

	_CompareResults(ocrResult, gtTxtValue) {
		if (ignoreSpaces) {
			ocrResult := StrReplace(ocrResult, " ")
			gtTxtValue := StrReplace(gtTxtValue, " ")
		}
		return ocrResult == gtTxtValue
	}

	_ShowPreviousImage(*) {
		if (imageListPosition == 1) {
			NotAllowedBox("Already at first one")
			return
		}
		imageListPosition -= 1
		_RefreshGui()
	}

	_ShowNextImage(*) {
		if (imageListPosition == imageList.Length) {
			NotAllowedBox("No more files")
			return
		}
		imageListPosition += 1
		_RefreshGui()
	}

	_GotoImagePosition(*) {
		imageListPosition := gotoPageNumber.Value
		_RefreshGui()
	}

	_GotoChange(ctrlObj, *) {
		if (!ctrlObj.Value) {
			return
		}
		if (ctrlObj.Value > imageList.Length) {
			ctrlObj.Value := imageList.Length
		} else if (imageList.Length < 1) {
			ctrlObj.Value := 1
		}
	}

	_CloseCb(*) {
		if (searchEnabled || ocrInProgress) {
			closeRequest := true
			return
		}
		btnCtrl.Gui.Opt("-Disabled")
		previewGui.Destroy()
	}

	_CheckGeneratedModelExistence() {
		generatedModelFile := DATA_DIR "\" MODEL_NAME ".traineddata"
		return FileExist(generatedModelFile)
	}
	
	_PsmChange(ctrlObj, *) {
		previewPsm := ctrlObj.Value
		if (previewPsm > 13) {
			previewPsm := 13
			ctrlObj.Value := previewPsm
		} else if (previewPsm < 1) {
			previewPsm := 1
			ctrlObj.Value := previewPsm
		}
		_RefreshGui()
	}
}
