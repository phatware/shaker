//
//  CoctailDetails.swift
//  shaker
//
//  Created by Stan Miasnikov on 12/9/22.
//

import SwiftUI
import WebKit

struct WebView : UIViewRepresentable {
    
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView  {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}


struct CoctailDetailsView: View {
    
    @EnvironmentObject var modelData: ShakerModel
    var rec_id: Int64
    var alcogol: Bool

    private var coctail : CoctailDetails {
        
        let info  = modelData.database.getRecipe(rec_id, alcohol: alcogol, noImage: false) as? [String:Any]
        
        let rating = info?["userrating"] as? Int ?? (info?["rating"] as? Int ?? 0)
        let star = "★"
        let star_part = "✩"
        var rstr = ""
        if rating < 1 {
            rstr = "Not rated yet"
        }
        else {
            for _ in 0..<rating {
                rstr += star
            }
            for _ in rating..<10 {
                rstr += star_part
            }
        }
        
        let c = CoctailDetails(name: info?["name"] as? String ?? "(Unknown)",
                               category: info?["category"] as? String ?? "",
                               rec_id: rec_id,
                               rating: rating,
                               enabled: info?["enabled"] as? Bool ?? false,
                               glass: info?["glass"] as? String ?? "",
                               shopping: info?["shopping"] as? String ?? "",
                               ingredients: info?["ingredients"] as? String ?? "",
                               instructions: info?["instructions"] as? String ?? "",
                               user_rec_id: info?["userrecord_id"] as? Int64 ?? 0,
                               user_rating: rstr,
                               note: info?["note"] as? String ?? "",
                               photo: info?["photo"] as? Image ?? nil)
        
        return c
    }
    
    
    var body: some View {
        
        // NavigationView {
            VStack {
                
                let str = "<html> <head><style type=\"text/css\">\nbody {font-family: \"Verdana\"; font-size: 36px;}\n-webkit-touch-callout: none;\n</style><style type=\"text/css\">\na {color:blue; text-decoration:none; font-size: 42px;}</style></head><body> <h2>\(coctail.name)</h2><h4>Glass:</h4> <ul><li>\(coctail.glass)</ul></li> <h4>Ingredients:</h4><p> \(coctail.ingredients!)</p><h4>Instructions:</h4><p>\(coctail.instructions!)</p> <h4>Shopping list:</h4><p>\(coctail.shopping)</p> <h4>Rating:</h4> <p>\(coctail.user_rating!)</p> </body></html>"
                
                WebView(htmlString: str)
                    .padding()
            }
        // }
        .navigationTitle(coctail.name)
        .toolbar {
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    print("button pressed")
                    
                }) {
                    Image(systemName: "camera")
                        //.renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                }
                Button(action: {
                    print("button pressed")
                    
                }) {
                    Image(systemName: "star")
                        //.renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                }
                Button(action: {
                    print("button pressed")
                    
                }) {
                    Image(systemName: "arrowshape.turn.up.right")
                        //.renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                }
            }
        }
    }
}

struct CoctailDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        CoctailDetailsView(rec_id: 234, alcogol: true)
            .environmentObject(ShakerModel())
    }
}
