' form_fields -- VB.NET port of examples\Vb6\acroform\form_fields
Imports System
Imports System.IO
Imports LumasPdfSdk

Module FormFields
    Private errDel As TErrorProc

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Return 0
    End Function

    Sub Main()
        Dim f As Integer, r As Integer
        Dim y As Double
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetPageCoords(pdf, TPageCoord.pcTopDown)

        LumasPdf.pdfAppend(pdf)
        y = 50.0
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 10.0, False, TCodepage.cp1252)
        LumasPdf.pdfWriteTextW(pdf, 50.0, y, "Text fields:")

        y = y + 15.0
        f = LumasPdf.pdfCreateTextField(pdf, "Text1", -1, 0, 0, 50.0, y, 200.0, 20.0)
        LumasPdf.pdfSetTextFieldValueW(pdf, f, "", "Single line text...", LumasPdfConsts.taLeft)

        y = y + 30.0
        f = LumasPdf.pdfCreateTextField(pdf, "Text2", -1, 1, 0, 50.0, y, 200.0, 50.0)
        LumasPdf.pdfSetTextFieldValueW(pdf, f, "", "This field accepts multi-line text. The maximum text length can be restricted if necessary.", LumasPdfConsts.taLeft)

        y = y + 60.0
        LumasPdf.pdfWriteTextW(pdf, 50.0, y, "A password field:")
        y = y + 15.0
        f = LumasPdf.pdfCreateTextField(pdf, "Text3", -1, 0, 0, 50.0, y, 200.0, 20.0)
        LumasPdf.pdfSetFieldFlags(pdf, f, LumasPdfConsts.ffPassword, False)
        LumasPdf.pdfSetTextFieldValueW(pdf, f, "", "**********", LumasPdfConsts.taLeft)

        y = y + 30.0
        LumasPdf.pdfWriteTextW(pdf, 50.0, y, "A fixed length field separated into combs:")
        y = y + 15.0
        f = LumasPdf.pdfCreateTextField(pdf, "Text4", -1, 0, 10, 50.0, y, 200.0, 20.0)
        LumasPdf.pdfSetFieldFlags(pdf, f, LumasPdfConsts.ffComb, False)

        y = 50.0
        LumasPdf.pdfWriteTextW(pdf, 350.0, y, "Choice fields:")
        y = y + 15.0
        f = LumasPdf.pdfCreateComboBox(pdf, "Combo1", 1, -1, 350.0, y, 200.0, 20.0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "", " Select a value...", 1)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Apple", "Apple", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Banana", "Banana", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Pear", "Pear", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Grape", "Grape", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Orange", "Orange", 0)

        y = y + 30.0
        f = LumasPdf.pdfCreateListBox(pdf, "List", True, -1, 350.0, y, 200.0, 50.0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Apple", "Apple", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Banana", "Banana", 1)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Pear", "Pear", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Grape", "Grape", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Orange", "Orange", 0)

        y = y + 60.0
        LumasPdf.pdfWriteTextW(pdf, 350.0, y, "Editable combo box:")
        y = y + 15.0
        f = LumasPdf.pdfCreateComboBox(pdf, "Combo2", 1, -1, 350.0, y, 200.0, 20.0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Apple", "Apple", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Banana", "Banana", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Pear", "Pear", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Grape", "Grape", 0)
        LumasPdf.pdfAddValToChoiceFieldW(pdf, f, "Orange", "Orange", 0)
        LumasPdf.pdfSetFieldFlags(pdf, f, LumasPdfConsts.ffEdit, False)
        LumasPdf.pdfSetFieldExpValueW(pdf, f, 1000, "Select or enter a value...", "", True)

        y = y + 30.0
        LumasPdf.pdfWriteTextW(pdf, 350.0, y, "Check boxes / Radio buttons:")

        y = y + 15.0
        LumasPdf.pdfChangeFontSize(pdf, 1.0)
        LumasPdf.pdfCreateCheckBox(pdf, "N1", "C1", 1, -1, 350.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "N2", "C2", 1, -1, 380.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "N3", "C1", 1, -1, 410.0, y, 20.0, 20.0)

        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 0, -1, 450.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 480.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 1, -1, 510.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 540.0, y, 20.0, 20.0)

        y = y + 30.0
        LumasPdf.pdfChangeFontSize(pdf, 15.0)
        LumasPdf.pdfSetCheckBoxChar(pdf, TCheckBoxChar.ccCircle)
        r = LumasPdf.pdfCreateRadioButton(pdf, "Radio1", "R1", 1, -1, 350.0, y, 20.0, 20.0)
        LumasPdf.pdfSetCheckBoxDefState(pdf, r, False)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 380.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R3", 0, r, 410.0, y, 20.0, 20.0)

        r = LumasPdf.pdfCreateRadioButton(pdf, "Radio2", "R1", 1, -1, 450.0, y, 20.0, 20.0)
        LumasPdf.pdfSetFieldFlags(pdf, r, LumasPdfConsts.ffRadioIsUnion, False)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 480.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R1", 1, r, 510.0, y, 20.0, 20.0)
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 540.0, y, 20.0, 20.0)
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
