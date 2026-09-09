// 19_northwind_preview -- POSIX port of examples/cpp/reporting/19_northwind_preview.cpp
// (itself a port of examples/delphi/reporting/19_northwind_preview.dpr).
//
// WHAT THIS EXAMPLE IS FOR (unchanged from the Windows/Delphi original): it is
// the "teaching" example. It assembles the .lrpt one labelled block at a time,
// STEP 1..14, so a reader can follow a report definition the way the engine
// reads it, and then it SHOWS the rendered job in the SDK's embedded viewer via
// rptPreviewA().
//
//     STEP 1  <report>        the document envelope + tag-language version
//     STEP 2  <page>          paper size, margins (all in millimetres)
//     STEP 3  <datasources>   *** DATA BINDING ***  <-- the one POSIX divergence
//     STEP 4  <params>        run-time inputs, referenced with {{var:Name}}
//     STEP 5  <styles>        named, reusable text/box styling
//     STEP 6  <bands> open    the ordered list of horizontal bands
//     STEP 7    reportheader  printed once, at the very top
//     STEP 8    pageheader     column captions, repeated on every page
//     STEP 9    groupheader    one per CategoryName -- the group break key
//     STEP 10   detail         iterates the bound rows (data="d")
//     STEP 11   groupfooter    per-category subtotals via inline SUM()/COUNT()
//     STEP 12   summary        grand totals over the whole dataset
//     STEP 13   pagefooter     page x of y, repeated on every page
//     STEP 14  </bands></report>
//
// ===========================================================================
//  PLATFORM DIVERGENCE (STEP 3 only) -- read this before comparing outputs
// ===========================================================================
// The Windows/Delphi original binds STEP 3 with
//
//     <datasource alias="d" provider="odbc"
//        conn="Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=...Northwind.mdb;"
//        query="SELECT c.CategoryName, p.ProductName, p.QuantityPerUnit,
//                      p.UnitPrice, p.UnitsInStock
//               FROM Categories c INNER JOIN Products p
//                 ON c.CategoryID = p.CategoryID
//               ORDER BY c.CategoryName, p.ProductName"/>
//
// Neither half of that connection exists on Linux/macOS:
//
//   1. THE PROVIDER. The engine's "odbc" report data provider has no POSIX
//      implementation. cpp/src/pdf/rpt_data_odbc.cpp guards its entire live
//      binding with `#if defined(_WIN32) && LUMAS_HAS_ODBC`; the #else branch
//      registers the provider (so the name still resolves) but its Open()
//      throws RPT_E_DATA_CONN, "ODBC runtime is not available on this system
//      (live ODBC binding is not yet implemented on non-Windows platforms)".
//      The binding is Win32-specific by construction: it LoadLibrary's
//      odbc32.dll and resolves every entry point with GetProcAddress. A POSIX
//      port would have to dlopen unixODBC's libodbc.so.2 instead.
//      NOTE: LUMAS_HAS_ODBC is ON on desktop POSIX, so every rpt* export still
//      links -- symbols are never gated away, only implementations. "It links"
//      is therefore not evidence that it connects.
//
//   2. THE DATA SOURCE. Northwind.mdb is a Microsoft Access / JET database.
//      Even with a unixODBC binding in place there is no Access/JET ODBC
//      driver for Linux or macOS to point it at.
//
// See reporting/16_data_odbc_northwind/README.md -- example 16, whose whole
// SUBJECT is the ODBC provider, is documented there rather than faked.
//
// This example's subject is the .lrpt walkthrough and the embedded preview, and
// the data binding is one step out of fourteen, so STEP 3 here uses the
// PORTABLE "csv" provider over the SAME 77 rows, in the SAME order, with the
// SAME five column names -- exported from that very Northwind.mdb with the
// exact SELECT above (Categories INNER JOIN Products, ORDER BY CategoryName,
// ProductName) and embedded below as NORTHWIND_CSV.
//
// ROW ORDER -- it looks wrong at first glance, and it is not. Within each
// category the rows are in ProductID order, not alphabetical: Chai, Chang,
// Guarana Fantastica, Sasquatch Ale, Steeleye Stout, Cote de Blaye, ... The
// Access/JET driver does not honour "ORDER BY p.ProductName" on this JOIN (the
// same ORDER BY against Products alone sorts correctly), so the Windows run
// receives ProductID order too -- its own committed 19_northwind.txt shows
// exactly this sequence. The rows are therefore reproduced verbatim in the order
// the ODBC run actually returned them, rather than "corrected" to alphabetical,
// which would have made every single detail line differ between platforms.
//
// UnitPrice is written with
// two decimals, which is lossless for every Northwind price and makes the csv
// provider infer vkFloat, matching the SQL_DECIMAL -> vkFloat mapping the ODBC
// provider produces on Windows; UnitsInStock infers vkInt as it does there.
// Every other line of the report definition, every style, every expression and
// every aggregate is byte-identical to the Windows version, so the exported
// PDF/text are directly comparable -- the only intended difference is the
// reportheader's "as of" line, which cannot honestly claim "live ODBC" here.
//
// THE PREVIEW HALF NEEDS NO DIVERGENCE, and in fact works BETTER here:
// rptPreviewA -> RptPreviewLir -> vwrShowFileW, and vwrShowFileW is a real
// GTK3 window on Linux (cpp/src/pdf/viewer_gtk.cpp) and Cocoa on macOS, while
// on Windows it is not implemented yet and returns false. The call BLOCKS until
// the window is closed. Pass --headless (or --no-preview) to skip it; that is
// how CI runs this. Unattended screenshotting is also supported by the viewer
// itself via LUMAS_VIEWER_TEST_SCREENSHOT=<path> (captures and closes ~2 s
// after the window maps), LUMAS_VIEWER_TEST_GOTOPAGE=N and
// LUMAS_VIEWER_TEST_SINGLEPAGE=1.
//
// Preview needs the RPT_FEAT_PREVIEW licence bit; the demo key in rptcommon.h
// is full-feature, so it is enabled.
// ===========================================================================
#include "rptcommon.h"
#include <cctype>
#include <string>

// -- The Northwind rows, exported from wrappers/vcl/Examples/Northwind.mdb with
//    the original example's SELECT (see the header). UTF-8, hex-escaped so this
//    source stays pure ASCII like every other file in this tree; the \xNN runs
//    are closed with an adjacent "" wherever the next character is itself a hex
//    digit, so the escape cannot swallow it.
static const char* NORTHWIND_CSV =
        "CategoryName,ProductName,QuantityPerUnit,UnitPrice,UnitsInStock\n"
        "Beverages,Chai,10 boxes x 20 bags,18.00,39\n"
        "Beverages,Chang,24 - 12 oz bottles,19.00,17\n"
        "Beverages,Guaran\xC3\xA1 Fant\xC3\xA1stica,12 - 355 ml cans,4.50,20\n"
        "Beverages,Sasquatch Ale,24 - 12 oz bottles,14.00,111\n"
        "Beverages,Steeleye Stout,24 - 12 oz bottles,18.00,20\n"
        "Beverages,C\xC3\xB4te de Blaye,12 - 75 cl bottles,263.50,17\n"
        "Beverages,Chartreuse verte,750 cc per bottle,18.00,69\n"
        "Beverages,Ipoh Coffee,16 - 500 g tins,46.00,17\n"
        "Beverages,Laughing Lumberjack Lager,24 - 12 oz bottles,14.00,52\n"
        "Beverages,Outback Lager,24 - 355 ml bottles,15.00,15\n"
        "Beverages,Rh\xC3\xB6nbr\xC3\xA4u Klosterbier,24 - 0.5 l bottles,7.75,125\n"
        "Beverages,Lakkalik\xC3\xB6\xC3\xB6ri,500 ml,18.00,57\n"
        "Condiments,Aniseed Syrup,12 - 550 ml bottles,10.00,13\n"
        "Condiments,Chef Anton's Cajun Seasoning,48 - 6 oz jars,22.00,53\n"
        "Condiments,Chef Anton's Gumbo Mix,36 boxes,21.35,0\n"
        "Condiments,Grandma's Boysenberry Spread,12 - 8 oz jars,25.00,120\n"
        "Condiments,Northwoods Cranberry Sauce,12 - 12 oz jars,40.00,6\n"
        "Condiments,Genen Shouyu,24 - 250 ml bottles,15.50,39\n"
        "Condiments,Gula Malacca,20 - 2 kg bags,19.45,27\n"
        "Condiments,Sirop d'\xC3\xA9rable,24 - 500 ml bottles,28.50,113\n"
        "Condiments,Vegie-spread,15 - 625 g jars,43.90,24\n"
        "Condiments,Louisiana Fiery Hot Pepper Sauce,32 - 8 oz bottles,21.05,76\n"
        "Condiments,Louisiana Hot Spiced Okra,24 - 8 oz jars,17.00,4\n"
        "Condiments,Original Frankfurter gr\xC3\xBCne So\xC3\x9F""e,12 boxes,13.00,32\n"
        "Confections,Pavlova,32 - 500 g boxes,17.45,29\n"
        "Confections,Teatime Chocolate Biscuits,10 boxes x 12 pieces,9.20,25\n"
        "Confections,Sir Rodney's Marmalade,30 gift boxes,81.00,40\n"
        "Confections,Sir Rodney's Scones,24 pkgs. x 4 pieces,10.00,3\n"
        "Confections,NuNuCa Nu\xC3\x9F-Nougat-Creme,20 - 450 g glasses,14.00,76\n"
        "Confections,Gumb\xC3\xA4r Gummib\xC3\xA4rchen,100 - 250 g bags,31.23,15\n"
        "Confections,Schoggi Schokolade,100 - 100 g pieces,43.90,49\n"
        "Confections,Zaanse koeken,10 - 4 oz boxes,9.50,36\n"
        "Confections,Chocolade,10 pkgs.,12.75,15\n"
        "Confections,Maxilaku,24 - 50 g pkgs.,20.00,10\n"
        "Confections,Valkoinen suklaa,12 - 100 g bars,16.25,65\n"
        "Confections,Tarte au sucre,48 pies,49.30,17\n"
        "Confections,Scottish Longbreads,10 boxes x 8 pieces,12.50,6\n"
        "Dairy Products,Queso Cabrales,1 kg pkg.,21.00,22\n"
        "Dairy Products,Queso Manchego La Pastora,10 - 500 g pkgs.,38.00,86\n"
        "Dairy Products,Gorgonzola Telino,12 - 100 g pkgs,12.50,0\n"
        "Dairy Products,Mascarpone Fabioli,24 - 200 g pkgs.,32.00,9\n"
        "Dairy Products,Geitost,500 g,2.50,112\n"
        "Dairy Products,Raclette Courdavault,5 kg pkg.,55.00,79\n"
        "Dairy Products,Camembert Pierrot,15 - 300 g rounds,34.00,19\n"
        "Dairy Products,Gudbrandsdalsost,10 kg pkg.,36.00,26\n"
        "Dairy Products,Flotemysost,10 - 500 g pkgs.,21.50,26\n"
        "Dairy Products,Mozzarella di Giovanni,24 - 200 g pkgs.,34.80,14\n"
        "Grains/Cereals,Gustaf's Kn\xC3\xA4""ckebr\xC3\xB6""d,24 - 500 g pkgs.,21.00,104\n"
        "Grains/Cereals,Tunnbr\xC3\xB6""d,12 - 250 g pkgs.,9.00,61\n"
        "Grains/Cereals,Singaporean Hokkien Fried Mee,32 - 1 kg pkgs.,14.00,26\n"
        "Grains/Cereals,Filo Mix,16 - 2 kg boxes,7.00,38\n"
        "Grains/Cereals,Gnocchi di nonna Alice,24 - 250 g pkgs.,38.00,21\n"
        "Grains/Cereals,Ravioli Angelo,24 - 250 g pkgs.,19.50,36\n"
        "Grains/Cereals,Wimmers gute Semmelkn\xC3\xB6""del,20 bags x 4 pieces,33.25,22\n"
        "Meat/Poultry,Mishi Kobe Niku,18 - 500 g pkgs.,97.00,29\n"
        "Meat/Poultry,Alice Mutton,20 - 1 kg tins,39.00,0\n"
        "Meat/Poultry,Th\xC3\xBCringer Rostbratwurst,50 bags x 30 sausgs.,123.79,0\n"
        "Meat/Poultry,Perth Pasties,48 pieces,32.80,0\n"
        "Meat/Poultry,Tourti\xC3\xA8re,16 pies,7.45,21\n"
        "Meat/Poultry,P\xC3\xA2t\xC3\xA9 chinois,24 boxes x 2 pies,24.00,115\n"
        "Produce,Uncle Bob's Organic Dried Pears,12 - 1 lb pkgs.,30.00,15\n"
        "Produce,Tofu,40 - 100 g pkgs.,23.25,35\n"
        "Produce,R\xC3\xB6ssle Sauerkraut,25 - 825 g cans,45.60,26\n"
        "Produce,Manjimup Dried Apples,50 - 300 g pkgs.,53.00,20\n"
        "Produce,Longlife Tofu,5 kg pkg.,10.00,4\n"
        "Seafood,Ikura,12 - 200 ml jars,31.00,31\n"
        "Seafood,Konbu,2 kg box,6.00,24\n"
        "Seafood,Carnarvon Tigers,16 kg pkg.,62.50,42\n"
        "Seafood,Nord-Ost Matjeshering,10 - 200 g glasses,25.89,10\n"
        "Seafood,Inlagd Sill,24 - 250 g  jars,19.00,112\n"
        "Seafood,Gravad lax,12 - 500 g pkgs.,26.00,11\n"
        "Seafood,Boston Crab Meat,24 - 4 oz tins,18.40,123\n"
        "Seafood,Jack's New England Clam Chowder,12 - 12 oz cans,9.65,85\n"
        "Seafood,Rogede sild,1k pkg.,9.50,5\n"
        "Seafood,Spegesild,4 - 450 g glasses,12.00,95\n"
        "Seafood,Escargots de Bourgogne,24 pieces,13.25,62\n"
        "Seafood,R\xC3\xB6""d Kaviar,24 - 150 g jars,15.00,101\n";

static const char* CSV_FILE = "19_northwind.csv";

// STEP 1-14: the report definition, assembled one labelled block at a time.
static std::string BuildReportXml() {
    std::string s;
    // -- STEP 1: document envelope -------------------------------------------
    s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    s += "<report name=\"Northwind Catalog\" tagLangVersion=\"1\">\n";
    // -- STEP 2: page geometry (millimetres) ---------------------------------
    s += "  <page width=\"210\" height=\"297\" marginLeft=\"15\" marginTop=\"15\"\n";
    s += "        marginRight=\"15\" marginBottom=\"15\"/>\n";
    // -- STEP 3: *** DATA BINDING *** ----------------------------------------
    //  POSIX: the portable "csv" provider over the Northwind rows this program
    //  just wrote next to itself. conn = the file path (relative to cwd, which
    //  ChdirToExe() put at this binary's own directory). The Windows original
    //  uses provider="odbc" against Northwind.mdb -- see the file header for
    //  exactly why that cannot work here.
    s += "  <datasources>\n";
    s += std::string("    <datasource alias=\"d\" provider=\"csv\" conn=\"") + CSV_FILE + "\"/>\n";
    s += "  </datasources>\n";
    // -- STEP 4: run-time parameters, read as {{var:Name}} -------------------
    s += "  <params>\n";
    s += "    <param name=\"Title\"   default=\"'Northwind Product Catalog'\"/>\n";
    s += "    <param name=\"Company\" default=\"'LumasPDF Trading Co.'\"/>\n";
    s += "  </params>\n";
    // -- STEP 5: named, reusable styles --------------------------------------
    s += "  <styles>\n";
    s += "    <style name=\"Bar\"     backColor=\"005F3A1F\" borderWidth=\"0\"/>\n";
    s += "    <style name=\"GrpBar\"  backColor=\"002A170F\" borderWidth=\"0\"/>\n";
    s += "    <style name=\"Title\"   fontName=\"Helvetica\" fontSize=\"22\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Sub\"     fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n";
    s += "    <style name=\"ColH\"    fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
    s += "    <style name=\"ColHR\"   fontName=\"Helvetica\" fontSize=\"8\"  bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Grp\"     fontName=\"Helvetica\" fontSize=\"12\" bold=\"1\" textColor=\"00FFFFFF\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Cell\"    fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" vAlign=\"1\"/>\n";
    s += "    <style name=\"CellR\"   fontName=\"Helvetica\" fontSize=\"9\"  textColor=\"002A170F\" hAlign=\"2\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Muted\"   fontName=\"Helvetica\" fontSize=\"8\"  textColor=\"008B7464\" vAlign=\"1\"/>\n";
    s += "    <style name=\"Sub L\"   fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\"/>\n";
    s += "    <style name=\"SubR\"    fontName=\"Helvetica\" fontSize=\"8.5\" bold=\"1\" textColor=\"005F3A1F\" hAlign=\"2\"/>\n";
    s += "    <style name=\"GTotL\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\"/>\n";
    s += "    <style name=\"GTotR\"   fontName=\"Helvetica\" fontSize=\"11\" bold=\"1\" textColor=\"00FFFFFF\" hAlign=\"2\"/>\n";
    s += "    <style name=\"Foot\"    fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\"/>\n";
    s += "    <style name=\"FootR\"   fontName=\"Helvetica\" fontSize=\"7.5\" textColor=\"008B7464\" hAlign=\"2\"/>\n";
    s += "  </styles>\n";
    // -- STEP 6: open the band list ------------------------------------------
    s += "  <bands>\n";
    // -- STEP 7: reportheader (once, at the very top) ------------------------
    s += "    <band kind=\"reportheader\" name=\"rh\" height=\"26\">\n";
    s += "      <shape name=\"hbar\"  x=\"0\" y=\"0\" w=\"180\" h=\"18\" style=\"Bar\" shape=\"0\"/>\n";
    s += "      <text  name=\"ttl\"   x=\"5\"  y=\"1\"  w=\"120\" h=\"10\" style=\"Title\" wordWrap=\"0\">{{var:Title}}</text>\n";
    s += "      <text  name=\"sub\"   x=\"95\" y=\"6\"  w=\"80\"  h=\"6\"  style=\"Sub\"   wordWrap=\"0\">{{var:Company}}</text>\n";
    // The Windows original says "from Northwind.mdb (live ODBC)". Saying that
    // here would be false -- this run is bound through the csv provider.
    s += "      <text  name=\"asof\"  x=\"0\"  y=\"20\" w=\"180\" h=\"4\"  style=\"Muted\" wordWrap=\"0\">Generated {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }} from Northwind data (csv provider)</text>\n";
    s += "    </band>\n";
    // -- STEP 8: pageheader (column captions, every page) --------------------
    s += "    <band kind=\"pageheader\" name=\"ph\" height=\"8\">\n";
    s += "      <shape name=\"cbar\" x=\"0\" y=\"0\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n";
    s += "      <text name=\"hP\"  x=\"3\"   y=\"1.5\" w=\"64\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PRODUCT</text>\n";
    s += "      <text name=\"hK\"  x=\"69\"  y=\"1.5\" w=\"44\" h=\"4\" style=\"ColH\"  wordWrap=\"0\">PACK</text>\n";
    s += "      <text name=\"hU\"  x=\"114\" y=\"1.5\" w=\"21\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">PRICE</text>\n";
    s += "      <text name=\"hS\"  x=\"137\" y=\"1.5\" w=\"18\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">STOCK</text>\n";
    s += "      <text name=\"hV\"  x=\"157\" y=\"1.5\" w=\"20\" h=\"4\" style=\"ColHR\" wordWrap=\"0\">VALUE</text>\n";
    s += "    </band>\n";
    // -- STEP 9: groupheader (break key = the CategoryName column) -----------
    s += "    <band kind=\"groupheader\" name=\"gh\" group=\"d.CategoryName\" height=\"9\">\n";
    s += "      <shape name=\"gbar\" x=\"0\" y=\"1\" w=\"180\" h=\"7\" style=\"GrpBar\" shape=\"0\"/>\n";
    s += "      <text  name=\"gname\" x=\"4\" y=\"1.7\" w=\"140\" h=\"5\" style=\"Grp\" wordWrap=\"0\">{{expr: d.CategoryName}}</text>\n";
    s += "    </band>\n";
    // -- STEP 10: detail (iterates the bound rows) ---------------------------
    s += "    <band kind=\"detail\" name=\"det\" height=\"6\" data=\"d\">\n";
    s += "      <shape name=\"zebra\" x=\"0\" y=\"0\" w=\"180\" h=\"6\" shape=\"0\" backColor=\"00F9F5F1\" visible=\"RowNum % 2 = 0\"/>\n";
    s += "      <text name=\"cP\" x=\"3\"   y=\"1\" w=\"64\" h=\"4\" style=\"Cell\"  wordWrap=\"0\">{{ProductName}}</text>\n";
    s += "      <text name=\"cK\" x=\"69\"  y=\"1\" w=\"44\" h=\"4\" style=\"Muted\" wordWrap=\"0\">{{QuantityPerUnit}}</text>\n";
    s += "      <text name=\"cU\" x=\"114\" y=\"1\" w=\"21\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0.00', UnitPrice) }}</text>\n";
    s += "      <text name=\"cS\" x=\"137\" y=\"1\" w=\"18\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{UnitsInStock}}</text>\n";
    s += "      <text name=\"cV\" x=\"157\" y=\"1\" w=\"20\" h=\"4\" style=\"CellR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', UnitPrice*UnitsInStock) }}</text>\n";
    s += "      <line name=\"drow\" orient=\"h\" scope=\"section\" vAlign=\"bottom\" width=\"0.15\" color=\"00E2D8CE\"/>\n";
    s += "    </band>\n";
    // -- STEP 11: groupfooter (per-category subtotals) -----------------------
    s += "    <band kind=\"groupfooter\" name=\"gf\" group=\"d.CategoryName\" height=\"7\">\n";
    s += "      <line name=\"gtop\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.4\" color=\"005F3A1F\"/>\n";
    s += "      <text name=\"sl\" x=\"3\"   y=\"1.5\" w=\"110\" h=\"4\" style=\"Sub L\" wordWrap=\"0\">Subtotal -- {{expr: d.CategoryName}} ({{expr: COUNT()}} products)</text>\n";
    s += "      <text name=\"sv\" x=\"137\" y=\"1.5\" w=\"40\"  h=\"4\" style=\"SubR\"  wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n";
    s += "    </band>\n";
    // -- STEP 12: summary (grand totals over the whole dataset) --------------
    s += "    <band kind=\"summary\" name=\"sm\" height=\"16\">\n";
    s += "      <shape name=\"tbar\" x=\"0\" y=\"2\" w=\"180\" h=\"10\" style=\"Bar\" shape=\"0\"/>\n";
    s += "      <text name=\"gl\" x=\"4\"   y=\"4.2\" w=\"120\" h=\"6\" style=\"GTotL\" wordWrap=\"0\">GRAND TOTAL -- {{expr: COUNT()}} products in {{expr: COUNTDISTINCT(d.CategoryName)}} categories</text>\n";
    s += "      <text name=\"gv\" x=\"120\" y=\"4.2\" w=\"56\"  h=\"6\" style=\"GTotR\" wordWrap=\"0\">{{expr: FORMATNUM('#,##0', SUM(UnitPrice*UnitsInStock)) }}</text>\n";
    s += "    </band>\n";
    // -- STEP 13: pagefooter (page x of y, every page) -----------------------
    s += "    <band kind=\"pagefooter\" name=\"pf\" height=\"9\">\n";
    s += "      <line name=\"ft\" orient=\"h\" scope=\"section\" vAlign=\"top\" width=\"0.3\" color=\"00B9B9B9\"/>\n";
    s += "      <text name=\"fl\" x=\"0\"   y=\"2.5\" w=\"120\" h=\"4\" style=\"Foot\"  wordWrap=\"0\">{{var:Company}} -- confidential</text>\n";
    s += "      <text name=\"fr\" x=\"120\" y=\"2.5\" w=\"57\"  h=\"4\" style=\"FootR\" wordWrap=\"0\">Page {{var:PageNo}} of {{var:TotalPages}}</text>\n";
    s += "    </band>\n";
    // -- STEP 14: close ------------------------------------------------------
    s += "  </bands>\n";
    s += "</report>\n";
    return s;
}

static bool FileExists(const char* p) { FILE* f = fopen(p, "rb"); if (f) { fclose(f); return true; } return false; }

static bool IsHeadless(int argc, char** argv) {
    for (int i = 1; i < argc; ++i) {
        std::string c = argv[i];
        for (size_t k = 0; k < c.size(); ++k) c[k] = (char)tolower((unsigned char)c[k]);
        if (c.find("--headless") != std::string::npos || c.find("--no-preview") != std::string::npos)
            return true;
    }
    return false;
}

int main(int argc, char** argv) {
    ChdirToExe();
    if (!BootEngine()) return 0;

    const char* Lrpt = "19_northwind.lrpt";
    const char* OutPdf = "19_northwind.pdf";
    const char* OutTxt = "19_northwind.txt";
    SI32 Pages = 0;

    // Drop the data next to the binary so the .lrpt's relative conn resolves and
    // so the reader can open the exact rows the report was bound to.
    std::string Csv(NORTHWIND_CSV);
    WriteText(CSV_FILE, Csv);
    printf("DATA: wrote %s (%d bytes, 77 Northwind rows + header)\n", CSV_FILE, (int)Csv.size());

    std::string Xml = BuildReportXml();
    WriteText(Lrpt, Xml);
    printf("STEP 1-14: wrote %s (%d bytes)\n", Lrpt, (int)Xml.size());

    TRPTJOB Job = rptOpenReportA(mEng, Lrpt);
    if (Job == 0) { printf("open failed\n"); DumpRptError(mEng); goto Cleanup; }

    rptSetParamStr(Job, "Title", "Northwind Product Catalog");
    rptSetParamStr(Job, "Company", "LumasPDF Trading Co.");

    if (rptRender(Job) == 0) { printf("render failed\n"); DumpRptError(mEng); goto CloseJob; }
    Pages = rptGetPageCount(Job);
    printf("RENDER: %d page(s) bound from the Northwind rows\n", (int)Pages);

    if (rptExportA(Job, RPT_EXP_PDF, OutPdf) == 0) { printf("pdf export failed\n"); DumpRptError(mEng); goto CloseJob; }
    if (rptExportA(Job, RPT_EXP_TEXT, OutTxt) == 0) { printf("text export failed\n"); DumpRptError(mEng); goto CloseJob; }
    printf("EXPORT: %s  +  %s\n", OutPdf, OutTxt);

    if (IsHeadless(argc, argv)) {
        printf("PREVIEW: skipped (--headless). Open %s to view.\n", OutPdf);
    } else {
        // Real GTK3 window on Linux / Cocoa on macOS; blocks until it is closed.
        // Needs a display (DISPLAY / Xvfb on a headless box).
        printf("PREVIEW: opening the embedded viewer -- close the window to continue...\n");
        if (rptPreviewA(Job, "Northwind Product Catalog") == 0) {
            printf("  preview failed (continuing -- not fatal):\n");
            DumpRptError(mEng);
        }
    }
CloseJob:
    rptCloseReport(Job);

    if (FileExists(OutPdf) && Pages >= 1)
        printf("OK: %s exists, %d page(s).\n", OutPdf, (int)Pages);
    else
        printf("VERIFY FAILED: PDF missing or zero pages\n");
Cleanup:
    rptDeleteEngine(mEng);
    pdfDeletePDF(mPdf);
    return 0;
}
