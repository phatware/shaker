/*
 *  UIConst.h
 *  WritePad
 *
 *  Created by Stanislav Miasnikov on 11/8/08.
 *  Copyright 2008 PhatWare Corp. All rights reserved.
 *
 */

#pragma once

#define kSwitchButtonWidth			98.0
#define kSwitchButtonHeight			27.0
#define kToolbarButtonWidth			297

#define kPaletteHeight				36.0
#define kPaletteWidth				185.0
#define kTextFieldHeight			31.0
#define kSliderWidth				120.0
#define kFontSelectorWidth			180.0

#define kToolbarHeight				44.0
#define kLeftMargin					20.0
#define kTopMargin					10.0
#define kSliderHeight				7.0
#define kUIProgressBarHeight		24.0
#define kTextFieldWidth				260.0	// initial width, but the table cell will dictact the actual width

#define kNewWordCellHeight			56.0
#define kWordCellHeight				44.0

#define kUIShortcutCellHeight		250.0
#define kUIShortcutFontSize			15.0

// UITableView row heights
#define kUIRowHeight				48.0
#define kUIRowLabelHeight			22.0
#define kFolderRowHeight			72.0

#define kCellLeftOffset				12.0
#define kCellTopOffset				12.0
#define kCellHeight					25.0
#define kPageControlHeight			24.0
#define kPageControlWidth			160.0

#define kLabelFontSize				14.0
#define kCellLabelHeight			20.0
#define kInsertValue				8.0

#define kCellTtitleOffset			5.0
#define kCellCommentOffset			36.0
#define kCellNoteDateOffset			30.0

#define kCustomButtonHeight			40.0
#define kProgressIndicatorSize		40.0
#define kImageGap					3.0
#define kNoteTextFontSize			14.0
#define kTitleFontSize				16.0
#define kNameFontSize				18.0
#define kLeftLabelWidth				100.0
#define kTaskCellHeight				60.0
#define kEntryCellHeight			60.0
#define kEventDetailLabelWidth		75.0
#define kCheckButtonSize			26.0

#define kPagesViewHeight            232.0

#define kInfoRowCount               8
#define kInfoRowHeight              38.0


#define SHADOWCELLHEIGHT			15.0

#define SUGGESTION_TIMEOUT          7.0

#define kGridStep					85.0
#define MIN_GRID                    5.0
#define DEFAULT_GRID                40.0
#define MAX_GRID                    100.0

#define BUFF_SIZE					4096
#define MIN_PAGESIZE                640
#define MAX_PAGESIZE                1656

#define DEFAULT_BACKGESTURELEN		(IS_PHONE ? 190 : 380)
#define MIN_BACKGESTURELEN			(IS_PHONE ? 100 : 200)
#define MAX_BACKGESTURELEN			(IS_PHONE ? 320 : 550)

#define DEFAULT_PENWIDTH			3.0
#define PHATPAD_PENWIDTH			2.0
#define DEFAULT_RECODELAY			1.0
#define MINIMUM_PENWIDTH            1.0
#define MAXIMUM_PENWIDTH            8.0
#define MIN_RECODELAY				0.3
#define MAX_RECODELAY				5.0
#define DEFAULT_RECOSYMBDELAY		0.33
#define MIN_RECOSYMBDELAY           0.2
#define MAX_RECOSYMBDELAY			0.9
#define DEFAULT_BLINKDELAY			0.6
#define DEFAULT_DBLTOUCHDELAY		0.3
#define MAX_UNDO_LEVELS				100
#define kBottomOffset				22
#define MIN_TOUCHANDHOLDDELAY       0.5
#define MAX_TOUCHANDHOLDDELAY       3.0
#define DEFAULT_TOUCHANDHOLDDELAY	0.8
#define DEFAULT_AUTOSCROLLDELAY		0.35
#define kStatusBarHeight			(MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width))
// #define kStatusBarHeight            (([UIApplication sharedApplication].isStatusBarHidden) ? 0 : 20)


#define STANDARD_POPOVER_WIDTH		340.0
#define STANDARD_POPOVER_HEIGHT		420.0
#define LARGE_POPOVER_HEIGHT		800.0
#define STYLES_POPOVER_HEIGHT		(55.0 + 80.0 + 5 * 48.0) // 455.0
#define FORMAT_POPOVER_HEIGHT       455.0
#define TOOLS_POPOVER_HEIGHT		380.0
#define FILEMANAGER_POPOVER_WIDTH   400.0

#define TAP_SPACIAL_SENSITIVITY     16.0

#define DEFAULT_STROKE_LEN          1000

#define kAnimationAlphaDuration		0.25
#define kDefaultAnimationDuration	0.3
#define kSlowAnimationDuration      0.5

#define kDefaultFontName			@"HelveticaNeue"

#define MIN_FONT_SIZE               10.0
#define MAX_FONT_SIZE               54.0
#define DEF_FONT_SIZE               22.0

#define COLORCTL_WIDTH              STANDARD_POPOVER_WIDTH
#define WIDTHCTL_HEIGHT             30.0
#define CTL_OFFSET                  15.0
#define COLORCTL_HEIGHT_DEFAULT     400.0

#define MIN_PEN_WIDTH               2.0
#define MAX_PEN_WIDTH               28.0

#define LineFlatness                0.5f
#define LineWidthMinDelta           0.12f
#define LineWidthStep               0.25f

#define kDefaultFontSize		    20.0f
#define KUIAboutBoxHeight		    240.0f

#define MAX_MESSAGE_LENGTH          140
#define MAX_IMAGE_WIDTH             620

#define CONTENT_INSET               0
#define FILE_SAVE_TIMEOUT           2.0f
#define SMS_MESSAGE_LENGTH          160
