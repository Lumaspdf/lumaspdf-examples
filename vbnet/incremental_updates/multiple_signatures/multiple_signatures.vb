' multiple_signatures -- VB.NET port of examples\Vb6\incremental_updates\multiple_signatures
Imports System
Imports System.IO
Imports LumasPdfSdk

Module modMultipleSignatures
    Private ErrDel As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Function SignFile(ByVal pdf As IntPtr, ByVal InFileName As String, ByVal OutFileName As String, ByVal FieldName As String, ByVal Reason As String, ByVal PosX As Double, ByVal VisibleSignature As Boolean) As Boolean
        Dim outName As String = OutFileName
        Dim usedTemp As Boolean = False
        If InFileName = OutFileName Then
            outName = Path.GetTempFileName()
            usedTemp = True
        End If

        LumasPdf.pdfCreateNewPDFW(pdf, outName)

        ' This special license key avoids the demo string that would invalidate previous signatures.
        LumasPdf.pdfSetLicenseKey(pdf, "SigDemo")

        LumasPdf.pdfSetImportFlags2(pdf, CUInt(LumasPdfConsts.if2IncrementalUpd))
        If LumasPdf.pdfOpenImportFileW(pdf, InFileName, LumasPdfConsts.ptOpen, "") < 0 Then Return False
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

        If VisibleSignature Then
            LumasPdf.pdfSetPageCoords(pdf, CInt(TPageCoord.pcTopDown))
            LumasPdf.pdfEditPage(pdf, 1)
            Dim sig As Integer = LumasPdf.pdfCreateSigField(pdf, FieldName, -1, PosX, 30.0, 180.0, 40.0)
            LumasPdf.pdfSetFieldBorderWidth(pdf, CUInt(sig), 0.0)
            LumasPdf.pdfEndPage(pdf)
        End If

        Dim ok As Boolean = LumasPdf.pdfCloseAndSignFile(pdf, "../../../test_files/test_cert.pfx", "123456", Reason, "")
        If ok AndAlso usedTemp Then
            If File.Exists(OutFileName) Then File.Delete(OutFileName)
            File.Move(outName, OutFileName)
        End If
        Return ok
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        ErrDel = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDel)

        Dim filePath As String = AppPath() & "\out.pdf"

        If SignFile(pdf, "../../../../license.PDF", filePath, "Signature1", "Test signature 1", 50.0, True) Then
            If SignFile(pdf, filePath, filePath, "Signature2", "Test signature 2", 430.0, True) Then
                If SignFile(pdf, filePath, filePath, "", "Test signature 3", 0.0, False) Then
                    If SignFile(pdf, filePath, filePath, "", "Test signature 4", 0.0, False) Then
                        Console.WriteLine("PDF file """ & filePath & """ successfully created!")
                    End If
                End If
            End If
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module
