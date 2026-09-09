' check_boxes -- VB.NET port of examples\Vb6\acroform\check_boxes
Imports System
Imports System.IO
Imports LumasPdfSdk

Module CheckBoxes
    Private Const clLtGray As UInteger = 12632256UI
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Sub Main()
        Dim act As Integer, f As Integer, r As Integer
        Dim y As Double
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 10.0, False, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, "Normal check boxes.")

        LumasPdf.pdfChangeFontSize(pdf, 1.0)
        f = LumasPdf.pdfCreateCheckBox(pdf, "N1", "C1", 1, -1, 50.0, 70.0, 20.0, 20.0)
        LumasPdf.pdfSetCheckBoxDefState(pdf, f, True)
        f = LumasPdf.pdfCreateCheckBox(pdf, "N2", "C2", 1, -1, 80.0, 70.0, 20.0, 20.0)
        LumasPdf.pdfSetCheckBoxDefState(pdf, f, True)
        f = LumasPdf.pdfCreateCheckBox(pdf, "N3", "C1", 1, -1, 110.0, 70.0, 20.0, 20.0)
        LumasPdf.pdfSetCheckBoxDefState(pdf, f, True)

        LumasPdf.pdfChangeFontSize(pdf, 10.0)
        LumasPdf.pdfWriteTextW(pdf, 50.0, 100.0, "Field group with check boxes.")

        LumasPdf.pdfChangeFontSize(pdf, 1.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 0, -1, 50.0, 120.0, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 80.0, 120.0, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 1, -1, 110.0, 120.0, 20.0, 20.0)

        LumasPdf.pdfChangeFontSize(pdf, 10.0)
        LumasPdf.pdfWriteFTextExW(pdf, 50.0, 150.0, 220.0, -1.0, LumasPdfConsts.taLeft, "This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.")

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0

        LumasPdf.pdfChangeFontSize(pdf, 1.0)
        LumasPdf.pdfSetCheckBoxChar(pdf, TCheckBoxChar.ccCircle)
        LumasPdf.pdfCreateCheckBox(pdf, "G2", "C1", 0, -1, 50.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G2", "C2", 0, -1, 80.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G2", "C3", 1, -1, 110.0, y, 20.0, 20.0)

        LumasPdf.pdfChangeFontSize(pdf, 10.0)
        LumasPdf.pdfWriteFTextExW(pdf, 300.0, 50.0, 250.0, -1.0, LumasPdfConsts.taLeft, "This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.")

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0

        LumasPdf.pdfChangeFontSize(pdf, 15.0)
        r = LumasPdf.pdfCreateRadioButton(pdf, "Radio1", "R1", 1, -1, 300.0, y, 20.0, 20.0)
        LumasPdf.pdfSetCheckBoxDefState(pdf, r, False)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 330.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R3", 0, r, 360.0, y, 20.0, 20.0)

        LumasPdf.pdfChangeFontSize(pdf, 10.0)
        f = LumasPdf.pdfCreateButtonW(pdf, "Reset", "Reset", -1, 400.0, y, 60.0, 20.0)
        LumasPdf.pdfSetFieldColor(pdf, f, TFieldColor.fcBackColor, TPDFColorSpace.csDeviceRGB, clLtGray)
        LumasPdf.pdfSetFieldBorderStyle(pdf, f, TBorderStyle.bsBevelled)

        act = LumasPdf.pdfCreateResetAction(pdf)
        LumasPdf.pdfAddActionToObj(pdf, TObjType.otField, TObjEvent.oeOnMouseUp, act, f)
        LumasPdf.pdfAddFieldToFormAction(pdf, act, r, True)

        y = y + 40.0
        LumasPdf.pdfChangeFontSize(pdf, 10.0)
        LumasPdf.pdfWriteFTextExW(pdf, 300.0, y, 250.0, -1.0, LumasPdfConsts.taLeft, "The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.")
        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0

        LumasPdf.pdfChangeFontSize(pdf, 15.0)
        r = LumasPdf.pdfCreateRadioButton(pdf, "Radio2", "R1", 1, -1, 300.0, y, 20.0, 20.0)
        LumasPdf.pdfSetFieldFlags(pdf, r, LumasPdfConsts.ffRadioIsUnion, False)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 330.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R1", 1, r, 360.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 390.0, y, 20.0, 20.0)
        LumasPdf.pdfEndPage(pdf)

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) <> 0 Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
