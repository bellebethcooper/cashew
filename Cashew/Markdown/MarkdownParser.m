//
//  MarkdownParser.m
//  Issues
//
//  Created by Hicham Bouabdallah on 5/21/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "MarkdownParser.h"
#import <limits.h>
#import <hoedown/html.h>
#import <hoedown/document.h>
#import <hoedown/escape.h>
#import "Cashew-Swift.h"

static unsigned int HOEDOWN_HTML_USE_TASK_LIST = (1 << 4);

#define USE_XHTML(opt) (opt->flags & HOEDOWN_HTML_USE_XHTML)
#define USE_BLOCKCODE_INFORMATION(opt) \
(opt->flags & HOEDOWN_HTML_BLOCKCODE_INFORMATION)
#define USE_TASK_LIST(opt) (opt->flags & HOEDOWN_HTML_USE_TASK_LIST)

static unsigned int HOEDOWN_HTML_BLOCKCODE_LINE_NUMBERS = (1 << 5);
static unsigned int HOEDOWN_HTML_BLOCKCODE_INFORMATION = (1 << 6);

typedef struct hoedown_buffer hoedown_buffer;

typedef struct hoedown_html_renderer_state_extra {
    
    /* More extra callbacks */
    hoedown_buffer *(*language_addition)(const hoedown_buffer *language,
                                         void *owner);
    void *owner;
    
} hoedown_html_renderer_state_extra;

// rndr_blockcode from HEAD. The "language-" prefix in class in needed to make
// the HTML compatible with Prism.
void hoedown_patch_render_blockcode(
                                    hoedown_buffer *ob, const hoedown_buffer *text, const hoedown_buffer *lang,
                                    const hoedown_renderer_data *data)
{
    if (ob->size) hoedown_buffer_putc(ob, '\n');
    
    hoedown_html_renderer_state *state = data->opaque;
    //hoedown_html_renderer_state_extra *extra = state->opaque;
    
    hoedown_buffer *front = NULL;
    hoedown_buffer *back = NULL;
    if (lang && USE_BLOCKCODE_INFORMATION(state))
    {
        front = hoedown_buffer_new(lang->size);
        back = hoedown_buffer_new(lang->size);
        
        hoedown_buffer *current = front;
        for (size_t i = 0; i < lang->size; i++)
        {
            uint8_t c = lang->data[i];
            if (current == front && c == ':')
                current = back;
            else
                hoedown_buffer_putc(current, c);
        }
        lang = front;
    }
    
    hoedown_buffer *mapped = NULL;
    //    if (lang && extra->language_addition)
    //    {
    //        mapped = extra->language_addition(lang, extra->owner);
    //        if (mapped)
    //            lang = mapped;
    //    }
    
    HOEDOWN_BUFPUTSL(ob, "<div><pre");
    if (state->flags & HOEDOWN_HTML_BLOCKCODE_LINE_NUMBERS)
        HOEDOWN_BUFPUTSL(ob, " class=\"line-numbers\"");
    if (back && back->size)
    {
        HOEDOWN_BUFPUTSL(ob, " data-information=\"");
        hoedown_buffer_put(ob, back->data, back->size);
        HOEDOWN_BUFPUTSL(ob, "\"");
    }
    HOEDOWN_BUFPUTSL(ob, "><code class=\"language-");
    if (lang && lang->size)
        hoedown_escape_html(ob, lang->data, lang->size, 0);
    else
        HOEDOWN_BUFPUTSL(ob, "none");
    HOEDOWN_BUFPUTSL(ob, "\">");
    
    if (text)
    {
        // Remove last newline to prevent prism from adding a blank line at the
        // end of code blocks.
        size_t size = text->size;
        if (size > 0 && text->data[size - 1] == '\n')
            size--;
        hoedown_escape_html(ob, text->data, size, 0);
    }
    
    HOEDOWN_BUFPUTSL(ob, "</code></pre></div>\n");
    
    hoedown_buffer_free(mapped);
    hoedown_buffer_free(front);
    hoedown_buffer_free(back);
}

// Supports task list syntax if HOEDOWN_HTML_USE_TASK_LIST is on.
// Implementation based on hoextdown.
void hoedown_patch_render_listitem(
                                   hoedown_buffer *ob, const hoedown_buffer *text, hoedown_list_flags flags,
                                   const hoedown_renderer_data *data)
{
    if (text)
    {
        hoedown_html_renderer_state *state = data->opaque;
        size_t offset = 0;
        if (flags & HOEDOWN_LI_BLOCK)
            offset = 3;
        
        // Do task list checkbox ([x] or [ ]).
        if (USE_TASK_LIST(state) && text->size >= 3)
        {
            if (strncmp((char *)(text->data + offset), "[ ]", 3) == 0)
            {
                HOEDOWN_BUFPUTSL(ob, "<li class=\"task-list-item\">");
                hoedown_buffer_put(ob, text->data, offset);
                if (USE_XHTML(state))
                    HOEDOWN_BUFPUTSL(ob, "<input type=\"checkbox\" />");
                else
                    HOEDOWN_BUFPUTSL(ob, "<input type=\"checkbox\">");
                offset += 3;
            }
            else if (strncmp((char *)(text->data + offset), "[x]", 3) == 0)
            {
                HOEDOWN_BUFPUTSL(ob, "<li class=\"task-list-item\">");
                hoedown_buffer_put(ob, text->data, offset);
                if (USE_XHTML(state))
                    HOEDOWN_BUFPUTSL(ob, "<input type=\"checkbox\" checked />");
                else
                    HOEDOWN_BUFPUTSL(ob, "<input type=\"checkbox\" checked>");
                offset += 3;
            }
            else
            {
                HOEDOWN_BUFPUTSL(ob, "<li>");
                offset = 0;
            }
        }
        else
        {
            HOEDOWN_BUFPUTSL(ob, "<li>");
            offset = 0;
        }
        size_t size = text->size;
        while (size && text->data[size - offset - 1] == '\n')
            size--;
        
        hoedown_buffer_put(ob, text->data + offset, size - offset);
    }
    HOEDOWN_BUFPUTSL(ob, "</li>");
}



@implementation MarkdownParser {
    hoedown_renderer *_htmlRenderer;
}

//    NSData *inputData = [text dataUsingEncoding:NSUTF8StringEncoding];
//    hoedown_document *document = hoedown_document_new(
//                                                      htmlRenderer, flags, kMPRendererNestingLevel);
//    hoedown_buffer *ob = hoedown_buffer_new(64);
//    hoedown_document_render(document, ob, inputData.bytes, inputData.length);
//    if (smartypants)
//    {
//        hoedown_buffer *ib = ob;
//        ob = hoedown_buffer_new(64);
//        hoedown_html_smartypants(ob, ib->data, ib->size);
//        hoedown_buffer_free(ib);
//    }
//    NSString *result = [NSString stringWithUTF8String:hoedown_buffer_cstr(ob)];
//    hoedown_document_free(document);
//    hoedown_buffer_free(ob);

- (instancetype)init
{
    self = [super init];
    if (self) {
        //        HOEDOWN_EXT_AUTOLINK = (1 << 3),
        //        HOEDOWN_EXT_STRIKETHROUGH = (1 << 4),
        //        HOEDOWN_EXT_UNDERLINE = (1 << 5),
        //        HOEDOWN_EXT_HIGHLIGHT = (1 << 6),
        //        HOEDOWN_EXT_QUOTE = (1 << 7),
        //        HOEDOWN_EXT_SUPERSCRIPT = (1 << 8),
        //        HOEDOWN_EXT_MATH = (1 << 9),
        //        _htmlRenderer = hoedown_html_renderer_new(HOEDOWN_HTML_USE_TASK_LIST | HOEDOWN_EXT_TABLES | HOEDOWN_EXT_UNDERLINE | HOEDOWN_EXT_AUTOLINK | HOEDOWN_EXT_STRIKETHROUGH | HOEDOWN_EXT_QUOTE | HOEDOWN_EXT_SUPERSCRIPT | HOEDOWN_HTML_HARD_WRAP | HOEDOWN_HTML_USE_XHTML | HOEDOWN_EXT_FENCED_CODE | HOEDOWN_EXT_HIGHLIGHT, 6);
        
        _htmlRenderer = hoedown_html_renderer_new(52, 6);
        
        
        _htmlRenderer->blockcode = hoedown_patch_render_blockcode;
        _htmlRenderer->listitem = hoedown_patch_render_listitem; // hoedown_patch_render_listitem;
        
        
        
    }
    return self;
}


- (NSString *)parse:(NSString *)str forRepository:(QRepository *)repo
{
    NSString *markdownText = str.length == 0 ? @"<i>No description provided.</i>" : str;
    NSString *pattern = @"(^\\r*?\\s*?[^-*\\s].+)(\\r*?\\n)(\\r*?\\s*[-*].*)";
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    NSParameterAssert(error == nil);
    
    NSString *replaced = [regex stringByReplacingMatchesInString:markdownText
                                                         options:0
                                                           range:NSMakeRange(0, [markdownText length])
                                                    withTemplate:@"$1$2\n$3"];
    
    pattern = @"(^\\r*?\\s*?[^-*\\s].+)(\\r*?\\n)(\\r*?```)";
    
    regex = [NSRegularExpression
             regularExpressionWithPattern:pattern
             options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    NSParameterAssert(error == nil);
    
    replaced = [regex stringByReplacingMatchesInString:replaced
                                               options:0
                                                 range:NSMakeRange(0, [replaced length])
                                          withTemplate:@"$1$2\n$3"];
    
    // Issue link i.e. #1234
    replaced = [self _linkifyIssueNumbersForMarkdown:replaced forRepository:repo];
    //    pattern = @"(^|\\s+)(\\#(\\d+))";
    //
    //    regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    //    NSParameterAssert(error == nil);
    //    NSString *template = [NSString stringWithFormat:@"$1[$2](cashew://repository=%@&issueNumber=$3)", repo.fullName];
    //    replaced = [regex stringByReplacingMatchesInString:replaced options:0 range:NSMakeRange(0, [replaced length]) withTemplate:template];
    
    
    
    // @handle
    replaced = [self _linkifyHandlesForMarkdown:replaced];
    
    markdownText = [replaced stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    markdownText = [markdownText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    NSData *inputData = [markdownText dataUsingEncoding:NSUTF8StringEncoding];
    hoedown_document *document = hoedown_document_new(_htmlRenderer, 1023, SIZE_MAX);
    hoedown_buffer *ob = hoedown_buffer_new(64);
    hoedown_document_render(document, ob, inputData.bytes, inputData.length);
    
    NSString *result = [NSString stringWithUTF8String:hoedown_buffer_cstr(ob)];
    
    hoedown_document_free(document);
    hoedown_buffer_free(ob);
    
    result = [result stringByReplacingOccurrencesOfString:@":+1:" withString: @"👍🏼"];
    
    result = [NSString emoji:result];
    return result;
}

- (NSString *)_linkifyIssueNumbersForMarkdown:(NSString *)markdown forRepository:(QRepository *)repo
{
    NSString *pattern = @"(^|\\s+)(\\#(\\d+))";
    NSError *error = nil;
    __block NSArray<NSValue *> *codeRanges = [self _codeBlockRangesForMarkdown:markdown];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    NSString *template = [NSString stringWithFormat:@"$1[$2](cashew://repository=%@&issueNumber=$3)", repo.fullName];
    NSParameterAssert(error == nil);
    if (codeRanges.count == 0) {
        NSString *replaced = [regex stringByReplacingMatchesInString:markdown options:0 range:NSMakeRange(0, [markdown length]) withTemplate:template];
        return replaced;
    }
    
    
    __block BOOL reachedEnd = false;
    __block NSString *replaced = markdown;
    __block NSUInteger startIndex = 0;
    while (!reachedEnd) {
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:replaced options:0 range:NSMakeRange(startIndex, replaced.length - startIndex)];
        reachedEnd = matches.count == 0;
        [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL didIntersect = false;
            NSRange resultRange = [result rangeAtIndex:1];
            NSRange resultRange2 = [result rangeAtIndex:2];
            //NSRange resultRange3 = [result rangeAtIndex:3];
            // DDLogDebug(@"MATCH -> [%@] [%@] [%@]", [replaced substringWithRange:resultRange], [replaced substringWithRange:resultRange2], [replaced substringWithRange:resultRange3]);
            for (NSValue *val in codeRanges) {
                NSRange codeRange = val.rangeValue;
                if (NSIntersectionRange(codeRange, resultRange).length > 0) {
                    didIntersect = true;
                    //DDLogDebug(@"DID INTERSECt");
                    break;
                }
            }
            
            if (didIntersect == false) {
                NSRange comboRange = NSMakeRange(resultRange.location, resultRange2.length + resultRange.length);
                // DDLogDebug(@"comboRange -> %@", [replaced substringWithRange:comboRange]);
                replaced = [regex stringByReplacingMatchesInString:replaced options:0 range:comboRange withTemplate:template];
                codeRanges = [self _codeBlockRangesForMarkdown:replaced];
                startIndex = (template.length - 6) + comboRange.location + comboRange.length; //(resultRange.length * 2);
                *stop = true;
            }
            reachedEnd = idx == matches.count - 1;
        }];
    }
    
    return replaced;
}

- (NSString *)_linkifyHandlesForMarkdown:(NSString *)markdown
{
    NSString *pattern = @"(@[^\\s]+)";
    NSError *error = nil;
    NSArray<NSValue *> *codeRanges = [self _codeBlockRangesForMarkdown:markdown];
    NSArray<NSValue *> *quoteRanges = [self _quoteBlockRangesForMarkdown:markdown];
    
    __block NSMutableArray *forbiddenRanges = [[NSMutableArray alloc] init];
    [forbiddenRanges addObjectsFromArray:codeRanges];
    [forbiddenRanges addObjectsFromArray:quoteRanges];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    NSString *template = @"[$1](cashew://assignee=$1)";
    NSParameterAssert(error == nil);
    if (forbiddenRanges.count == 0) {
        NSString *replaced = [regex stringByReplacingMatchesInString:markdown options:0 range:NSMakeRange(0, [markdown length]) withTemplate:template];
        return replaced;
    }
    
    
    
    __block BOOL reachedEnd = false;
    __block NSString *replaced = markdown;
    __block NSUInteger startIndex = 0;
    while (!reachedEnd) {
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:replaced options:0 range:NSMakeRange(startIndex, replaced.length - startIndex)];
        reachedEnd = matches.count == 0;
        [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL didIntersect = false;
            NSRange resultRange = [result rangeAtIndex:1];
            // DDLogDebug(@"MATCH -> %@", [replaced substringWithRange:resultRange]);
            for (NSValue *val in forbiddenRanges) {
                NSRange codeRange = val.rangeValue;
                if (NSIntersectionRange(codeRange, resultRange).length > 0) {
                    didIntersect = true;
                    //  DDLogDebug(@"DID INTERSECt");
                    break;
                }
            }
            
            //NSLog(@"text = %@ Did Intersect = %@", [replaced substringWithRange:resultRange], didIntersect?@"YES":@"NO");
            NSString *previousChar = resultRange.location > 0 ? [replaced substringWithRange:NSMakeRange(resultRange.location - 1, 1)] : @"";
            //NSLog(@"text = %@ Did Intersect = %@ previous = (%@)", [replaced substringWithRange:resultRange], didIntersect?@"YES":@"NO", previousChar);
            if (didIntersect == false && [@[ @"", @"\n", @"\r", @"\t", @" "] containsObject:previousChar] == true ) {
                replaced = [regex stringByReplacingMatchesInString:replaced options:0 range:resultRange withTemplate:template];
                //codeRanges = [self _codeBlockRangesForMarkdown:replaced];
                NSArray<NSValue *> *codeRanges = [self _codeBlockRangesForMarkdown:replaced];
                NSArray<NSValue *> *quoteRanges = [self _quoteBlockRangesForMarkdown:replaced];
                forbiddenRanges = [[NSMutableArray alloc] init];
                [forbiddenRanges addObjectsFromArray:codeRanges];
                [forbiddenRanges addObjectsFromArray:quoteRanges];
                
                startIndex = (template.length - 4) + resultRange.location + (resultRange.length * 2);
                *stop = true;
            }
            reachedEnd = idx == matches.count - 1;
        }];
    }
    
    return replaced;
}


- (NSArray<NSValue *> *)_quoteBlockRangesForMarkdown:(NSString *)markdown
{
    NSMutableArray<NSValue *> *values = [NSMutableArray new];
    NSString *pattern = @"^(\\s*?>.*$)";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    NSParameterAssert(error == nil);
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:markdown options:0 range:NSMakeRange(0, markdown.length)];
    if (matches.count == 0) {
        return values;
    }
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [values addObject:[NSValue valueWithRange:[obj rangeAtIndex:1]]];
    }];
    
    return values;
}

- (NSArray<NSValue *> *)_codeBlockRangesForMarkdown:(NSString *)markdown
{
    NSMutableArray<NSValue *> *values = [NSMutableArray new];
    NSString *pattern = @"(`+[^`]+`+)";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:&error];
    NSParameterAssert(error == nil);
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:markdown options:0 range:NSMakeRange(0, markdown.length)];
    if (matches.count == 0) {
        return values;
    }
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [values addObject:[NSValue valueWithRange:[obj rangeAtIndex:1]]];
    }];
    
    return values;
}

@end
