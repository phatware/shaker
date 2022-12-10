//
//  CollasibleSection.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/30/22.
//

import SwiftUI

struct CollapsibleSection<Content: View>: View
{
    private let title: String
    private let content: Content
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    @State private var isExpanded = false
    
    init(title: String, alignment: HorizontalAlignment = .leading, spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.title = title
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View
    {
        // TODO: fix colors
        Section(header: HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            Spacer()
            Image(systemName: "chevron.up")
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .foregroundColor(.white)
                .padding(.trailing, 10)
        }
            .background(Color.blue)
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
                VStack(alignment: alignment, spacing: spacing) {
                    content
                }
                //.animation(.easeOut, value: 0)
                //.transition(.slide)
                // .clipped()
            }
        }
    }
}
