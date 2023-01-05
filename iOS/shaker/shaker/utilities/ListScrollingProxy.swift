//
//  ListScrollingProxy.swift
//  shaker
//
//  Created by Stan Miasnikov on 1/4/23.
//

import SwiftUI

class ListScrollingProxy
{
    enum Action {
        case end
        case top
        case point(point: CGPoint)     // << bonus !!
    }
    
    private var scrollView: UIScrollView?
    
    func catchScrollView(for view: UIView) {
        if nil == scrollView {
            scrollView = view.enclosingScrollView()
        }
    }
    
    func scrollTo(_ action: Action) {
        if let scroller = scrollView {
            var rect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
            switch action {
            case .end:
                rect.origin.y = scroller.contentSize.height +
                scroller.contentInset.bottom + scroller.contentInset.top - 1
            case .point(let point):
                rect.origin.y = point.y
            default: {
                // default goes to top
            }()
            }
            scroller.scrollRectToVisible(rect, animated: true)
        }
    }
}

extension UIView
{
    func enclosingScrollView() -> UIScrollView? {
        var next: UIView? = self
        repeat {
            next = next?.superview
            if let scrollview = next as? UIScrollView {
                return scrollview
            }
        } while next != nil
        return nil
    }
}

struct ListScrollingHelper: UIViewRepresentable
{
    let proxy: ListScrollingProxy // reference type
    
    func makeUIView(context: Context) -> UIView {
        return UIView() // managed by SwiftUI, no overloads
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        proxy.catchScrollView(for: uiView) // here UIView is in view hierarchy
    }
}
