//
//  CollasibleSection.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/30/22.
//

import SwiftUI

///////////////////////////////////////////////////////////////////////////////////////////
///Collapsible Section CONTENT view

struct CollapsibleSection<Content: View>: View
{
    private let title: String
    private let content: Content
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    @State private var isExpanded: Bool
    
    init(title: String, setExpanded: Bool, alignment: HorizontalAlignment = .leading, spacing: CGFloat = 10, @ViewBuilder content: () -> Content)
    {
        self.title = title
        self.alignment = alignment
        self.spacing = spacing
        _isExpanded = /*State<Bool>*/.init(initialValue: setExpanded)
        self.content = content()
    }

    var body: some View
    {
        // TODO: fix colors
        Section(header: HStack {
            Text(title)
                .font(.title2)
                .foregroundColor(.black)
                .padding()
            Spacer()
            Image(systemName: "chevron.up")
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .foregroundColor(.black)
                .padding(.trailing, 10)
        }
            .background(Color(white: 0.95))
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: 0,
                bottom: 0,
                trailing: 0))
            .onTapGesture {
                withAnimation(.linear) { isExpanded.toggle() }
            }
        ) {
            // list items
            if isExpanded {
                content
                    .animation(.easeOut, value: 0)
                    .transition(.slide)
                    // .clipped()
            }
            else {
//                VStack(spacing: self.spacing) {
//                    EmptyView()
//                }
//                .listRowInsets(EdgeInsets(
//                    top: 0,
//                    leading: 0,
//                    bottom: 0,
//                    trailing: 0))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .expandCollapse)) { notofication in
            // If you are passing an object, this can be "notification in"
            // print("\(notofication)")
            
            if let val = notofication.object as? Bool {
                isExpanded = val
            }
            
            // Do something here as a result of the notification
        }
    }
}
