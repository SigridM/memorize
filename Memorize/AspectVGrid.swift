//
//  AspectVGrid.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 9/21/22.
//

import SwiftUI

/// A View that maintains the aspect ratio of its contents while maximizing the number of items
/// in the grid to avoid vertical scrolling.
struct AspectVGrid<Item, ItemView>: View where ItemView: View, Item: Identifiable {
 
    ///The models whose view representations are laid out in a grid
    var items: [Item]
    
    /// The ratio of width to height that will be maintained
    var aspectRatio: CGFloat
    
    /// The closure that converts each model in the grid into a view, given the model and the currently calculated width.
    var content: (Item, CGFloat) -> ItemView

    init(items: [Item],
         aspectRatio: CGFloat,
         content: @escaping (Item, CGFloat) -> ItemView) {
        self.items = items
        self.aspectRatio = aspectRatio
        self.content = content
    }
    
    
    
    /// Creates and returns the main view for the AspectVGrid, using a GeometryReader to guide the width of each item in
    /// the grid.
    var body: some View {
        GeometryReader { geometry in
            VStack { // This, plus the spacer, will make the whole GeometryReader of flexible size
                let width = widthThatFits(
                    itemCount: items.count,
                    in: geometry.size,
                    itemAspectRatio: aspectRatio)
                LazyVGrid(columns: [gridItemOf(width: width)]) {
                    ForEach(items) {item in
                        content(item, width).aspectRatio(aspectRatio, contentMode: .fit)
                    }
                }
                Spacer(minLength: 0)
            }

        }
    }
    
    /// Creates and returns a GridItem whose size is based on the size of the ScrollView in which it lives. Since this is called every
    /// time the View is rebuilt, it gets called when cards are added or removed, so the card width and the radius for the corners
    /// of the cards gets updated whenever this is called.
    /// - Parameter size: the CGSize of the ScrollView that holds the GridItem
    /// - Returns: a GridItem sized to the correct size
    private func gridItemOf(width: CGFloat) -> GridItem {
        return GridItem(
            .adaptive(
                minimum: width,
                maximum: width
            )
        )
    }
        
    /// Return the exact width of a card that puts all cards on the table without requiring vertical scrolling.
    ///
    /// We will be looping through the number of cards to see how they fit, but to be smart about it, we won't
    /// start at 1. There is a minium number of columns that should fit according to these forumulae:
    ///
    ///  let a = aspect ratio of the cards
    ///
    ///  let f = the factor by which to apply the card ratio (effectively, the card height)
    ///
    ///  let c = number of columns
    ///
    ///  let r = number of rows
    ///
    ///  let w = view width
    ///
    ///  let h = view height
    ///
    ///  let t = total number of cards
    ///
    ///  There are three unknowns, and three equations. The unknowns are the card height, the number of rows and the number
    ///  of columns. (f, r and c). The card width is also unknown, but can be derived by multiplying the aspect ratio times the
    ///  card height.
    ///
    ///  The three equations are:
    ///
    ///  afc = w  (multiply the aspect ratio by the card height and number of columns to exactly fit within the view width)
    ///
    ///  cr = t (the number of columns times the number of rows - which may be fractional - is the total number of cards)
    ///
    ///  and
    ///
    ///  fr ≤ h (the height of the cards times the number of rows must be less than the view height to prevent scrolling)
    ///
    ///  ** Technically, the equation should read "f ceil(r) ≤ h" but since by definition r ≤ ceil(r), the inequality still
    ///  holds when we solve for r (rearranging to ceil(r) ≤ h/f).**
    ///
    ///  Rearranging and substituting to solve for c, the final equation is:
    ///
    ///  c ≥ √(wt/(ah))
    ///
    ///  and because wt/(ah) will rarely be a perfect square, c will be a fraction. Since c needs to be an integer large enough to
    ///  fit all the cards in a row, not just a fraction of a card, we can take the ceiling of c to start our loop.
    ///
    ///  c = ceil(√(wt/(ah)))
    ///
    ///  But w isn't really the width of the view, practially speaking. Because the GridItem adds the border width to both sides
    ///  of the card, the width is effectively smaller than w by the number of columns times twice the border width. (And the
    ///  height is effectively smaller than h by the number of rows times twice the border width.)
    ///
    ///  Hence, the actual formula is:
    ///
    ///  let b = the border allowance (twice one border)
    ///
    ///  let c = ceil(√(wt/(ah))
    ///
    ///  r = ceil(t/c)
    ///
    ///  c' = ceil(√((w - cb) * t / (a * (h -rb))))
    ///
    ///  And we start our loop at c'.
    ///
    ///  For the last check, the view may be wide enough and short enough, with few enough cards, that we can't
    ///  divide the width by the number of cards to maximize the card width without having the height of the cards extend
    ///  past the  bottom of the view. In that case, we will fall out of the bottom of the loop, and then we just use the
    ///  view height for the card height, and apply the aspect ratio to get the card width.
    /// - Parameter size: the CGSize containing the width and height of the view area
    /// - Returns: a CGFloat that is the exact width that will allow all cards to fit within the view without requiring
    ///   vertical scrolling
    private func widthThatFits(itemCount: Int, in size: CGSize, itemAspectRatio: CGFloat) -> CGFloat {
        
        if itemCount == 0 {return 0}
            
        let borderAllowance = ViewConstants.cardBorderWidth * 2
        let viewWidth = size.width
        let viewHeight = size.height
        let totalCards = CGFloat(itemCount)
        let columnsWithoutBorders = ceil(sqrt(viewWidth * totalCards /
                                              (itemAspectRatio * viewHeight)
                                              )
                                         )
        let numRows = ceil(totalCards / columnsWithoutBorders)
        let borderViewWidth = viewWidth - (columnsWithoutBorders * borderAllowance)
        let borderViewHeight = viewHeight - (numRows * borderAllowance)
        
        let columnsWithBorders = ceil(sqrt(borderViewWidth * totalCards /
                                           (itemAspectRatio * borderViewHeight)
                                           )
                                      )
                
        var columnNumber = Int(columnsWithBorders)

        while columnNumber <= (itemCount) {
            let floatColumnNumber = CGFloat(columnNumber)
            let actualViewWidth = viewWidth - (borderAllowance * floatColumnNumber)
            let columnWidth = actualViewWidth / floatColumnNumber
            
            // because columnWidth is already taking the borderAllowance into consideration,
            // and rowHeight is based on the columnWidth, don't include borderAllowance again
            let rowHeight = columnWidth / itemAspectRatio
            let numRows = ceil(totalCards / floatColumnNumber)
            
            if (rowHeight * numRows <= viewHeight) { // fits
                // I have to admit that I don't quite understand why I have to subtract
                // borderAllowance again here, since columnWidth was based on a reduced
                // viewWidth, and (columnWidth + borderAllowance) * floatColumnNumber is equal
                // to the viewWidth, but it doesn't work without it, and I've already spent too
                // much time on it!!
                // And... it seems like I don't have to subtract the borderAllowance, just
                // half of that: the cardBorderWidth. Go figure.
                let answer = columnWidth - ViewConstants.cardBorderWidth
                return answer
            }
            columnNumber += 1
        }
        // fell out of bottom of the loop without returning a width...
        let answer = borderViewHeight * itemAspectRatio
        return answer
    }

}

