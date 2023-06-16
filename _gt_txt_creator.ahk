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

; Helps creating .gt.txt files by showin image and asking for content

VerifyGtTxtFiles(parentGui) {
	for fileExtension in SUPPORTED_IMAGE_FILES {
		foundFiles := FindAllFiles(GROUND_TRUTH_DIR "\*" fileExtension)
		for imagePath in foundFiles {
			gtTxtPath := StrCutEnd(imagePath, StrLen(fileExtension)) ".gt.txt"
			if (!FileExist(gtTxtPath)) {
				GtTxtPrompt(imagePath, gtTxtPath, parentGui)
			}
		}
	}
}

GtTxtPrompt(imageFullPath, gtTxtPath, parentGui) {
	if (START_MODEL) {
		recognizedValue := OcrImageFile(imageFullPath, START_MODEL)
	} else {
		recognizedValue := ""
	}

	Width := A_ScreenWidth // 2

	imageGui := Gui("+Resize -DPIScale +Owner" parentGui.Hwnd, "Trained Image")

	imageGui.Add("Text", "w" Width, "Following Ground Truth image file '" imageFullPath "' do not have corresponding '.gt.txt' file. Please input proper value and click the 'Save' button (or press Enter) to create it.")
	guiCtrl := imageGui.Add("Edit", "xm w" Width, recognizedValue)
	saveBtn := imageGui.Add("Button", "default section xm", "&Save")
	saveBtn.OnEvent("Click", SaveGtTxtFile)
	skipBtn := imageGui.Add("Button", "ys", "S&kip")
	skipBtn.OnEvent("Click", SkipThisFile)
	exitBtn := imageGui.Add("Button", "ys", "&Exit")
	exitBtn.OnEvent("Click", ExitAppCb)

	MyPic := imageGui.Add("Pic", "xm")
	MyPic.Value := "*w" Width " *h-1 " imageFullPath  ; Load the image.


	imageGui.Title := imageFullPath
	imageGui.Show("xCenter AutoSize")  ; Resize the window to match the picture size.
	imageGui.OnEvent("Close", SkipThisFile)
	imageGui.OnEvent("Escape", SkipThisFile)
	parentGui.Opt("+Disabled")
	WinWaitClose(imageGui)

	SaveGtTxtFile(*) {
		FileSave(gtTxtPath, guiCtrl.Value "`n")
		parentGui.Opt("-Disabled")
		imageGui.Destroy()
	}

	SkipThisFile(*) {
		parentGui.Opt("-Disabled")
		imageGui.Destroy()
	}

	ExitAppCb(*) {
		ExitApp
	}
}
