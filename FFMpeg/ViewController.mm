//
//  ViewController.m
//  FFMpeg
//
//  Created by Wangjianlong on 2021/12/19.
//

#import "ViewController.h"

#import "JLRecordPCMOrYUV.hpp"
#import "JLPlayPCM.hpp"
#import "JLPCMToWAV.hpp"
#import "JLPlayWAV.hpp"
#import "JLAudioResample.hpp"
#import "JLAACACodec.hpp"

#import <Masonry/Masonry.h>
#import "YUVView.h"
#import "YUVMacOSPlayer.h"
#import "YUVPlayItem.h"

//#include <iostream>
//#include <fstream>

#define margin 30
#define btnH 30
#define btnW 144

@interface ViewController ()
<
NSTabViewDelegate
,NSTableViewDataSource
>
{
    JLRecordPCMOrYUV *recordObj;
    JLPlayPCM *playPCMObj;
    JLPlayWAV *playWAVObj;
    FILE * file;
}

@property(nonatomic, strong) NSSwitch *beiginRecordSwitch;
@property(nonatomic, assign) BOOL stopRecord;
@property(nonatomic, assign) BOOL stopPlay;

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTableView *tableView;


@property (nonatomic, strong) YUVView * playView;

@property (nonatomic, strong) YUVMacOSPlayer *osPlayer;

@end

@implementation ViewController

//#define filename @"a"
//#define yuv_width 1920
//#define yuv_height 1372

//#define filename @"2"
//#define yuv_width 310
//#define yuv_height 522

//#define filename @"file"
//#define yuv_width 176
//#define yuv_height 144

- (void)viewDidLoad {
    [super viewDidLoad];

    _osPlayer = [[YUVMacOSPlayer alloc] initWithFrame:CGRectMake(20,7*margin,640,480)];
    
    YUVPlayItem *yuv = [[YUVPlayItem alloc] init];
//    yuv.w = 640;
//    yuv.h = 457;
//    yuv.fps = 30;
//    yuv.pixelFormat = YUVPlayItemPixFormateYUV420P;
//    yuv.fileName = @"/Users/jl/Downloads/AVA/11-YUV420P.yuv";
    
    
//    yuv.w = 640;
//    yuv.h = 1080;
//    yuv.fps = 30;
//    yuv.pixelFormat = YUVPlayItemPixFormateYUV420P;
//    yuv.fileName = @"/Users/jl/Downloads/AVA/050.yuv";
    
    yuv.w = 960;
    yuv.h = 720;
    yuv.fps = 30;
    yuv.pixelFormat = YUVPlayItemPixFormateYUV420P;
    yuv.fileName = @"/Users/jl/Downloads/AVA/xq.yuv";
    

    [_osPlayer setUpYUVItem:yuv];
//    [osPlayer play];
    [self.view addSubview:_osPlayer];


    NSButton *beiginPlayYUVBtn = [NSButton buttonWithTitle:@"开始播放yuv" target:self action:@selector(play:)];
    beiginPlayYUVBtn.frame = CGRectMake(0, 6*margin, btnW, btnH);
    [self.view addSubview:beiginPlayYUVBtn];
    
    NSButton *stopPlayYUVBtn = [NSButton buttonWithTitle:@"停止播放yuv" target:self action:@selector(stop)];
    stopPlayYUVBtn.frame = CGRectMake(btnW+margin, 6*margin, btnW, btnH);
    [self.view addSubview:stopPlayYUVBtn];

    NSButton *beiginRecordBtn = [NSButton buttonWithTitle:@"开始录音pcm" target:self action:@selector(beginRecord:)];
    beiginRecordBtn.frame = CGRectMake(0, 0, btnW, btnH);
    [self.view addSubview:beiginRecordBtn];


    NSButton *endRecordBtn = [NSButton buttonWithTitle:@"停止录音pcm" target:self action:@selector(endRecord:)];
    endRecordBtn.frame = CGRectMake(200, 0, btnW, btnH);
    [self.view addSubview:endRecordBtn];

    NSButton *beiginPlayBtn = [NSButton buttonWithTitle:@"开始播放pcm" target:self action:@selector(beginPlay:)];
    beiginPlayBtn.frame = CGRectMake(0, margin, btnW, btnH);
    [self.view addSubview:beiginPlayBtn];


    NSButton *endPlayBtn = [NSButton buttonWithTitle:@"停止播放pcm" target:self action:@selector(endPlay:)];
    endPlayBtn.frame = CGRectMake(200, margin, btnW, btnH);
    [self.view addSubview:endPlayBtn];


    NSButton *beiginPlayWAVBtn = [NSButton buttonWithTitle:@"开始播放wav" target:self action:@selector(beginPlayWAV:)];
    beiginPlayWAVBtn.frame = CGRectMake(0, 3*margin, btnW, btnH);
    [self.view addSubview:beiginPlayWAVBtn];


    NSButton *endPlayWAVBtn = [NSButton buttonWithTitle:@"停止播放wav" target:self action:@selector(endPlayWAV:)];
    endPlayWAVBtn.frame = CGRectMake(200, 3*margin, btnW, btnH);
    [self.view addSubview:endPlayWAVBtn];


    _beiginRecordSwitch = [[NSSwitch alloc] init];
    _beiginRecordSwitch.frame = CGRectMake(400, 0, 44, btnH);
    [self.view addSubview:_beiginRecordSwitch];


    _beiginRecordSwitch.state = NSControlStateValueOn;

    NSButton *pcmToWAVBtn = [NSButton buttonWithTitle:@"开始转换pcm2wav" target:self action:@selector(beginConvert:)];
    pcmToWAVBtn.frame = CGRectMake(0, 2*margin, btnW, btnH);
    [self.view addSubview:pcmToWAVBtn];


    NSButton *audioResampleBtn = [NSButton buttonWithTitle:@"音频重采样" target:self action:@selector(audioResample:)];
    audioResampleBtn.frame = CGRectMake(200, 2*margin, btnW, btnH);
    [self.view addSubview:audioResampleBtn];


    NSButton *aacEncodeBtn = [NSButton buttonWithTitle:@"aac编码" target:self action:@selector(aacEncode:)];
    aacEncodeBtn.frame = CGRectMake(0, 4*margin, btnW, btnH);
    [self.view addSubview:aacEncodeBtn];

    NSButton *aacDecodeBtn = [NSButton buttonWithTitle:@"aac解码" target:self action:@selector(aacDecode:)];
    aacDecodeBtn.frame = CGRectMake(200, 4*margin, btnW, btnH);
    [self.view addSubview:aacDecodeBtn];

    NSButton *beiginRecordYUVBtn = [NSButton buttonWithTitle:@"开始录制yuv" target:self action:@selector(beginRecordYUV:)];
    beiginRecordYUVBtn.frame = CGRectMake(0, 5*margin, btnW, btnH);
    [self.view addSubview:beiginRecordYUVBtn];


    NSButton *endRecordYUVBtn = [NSButton buttonWithTitle:@"停止录制yuv" target:self action:@selector(endRecordYUV:)];
    endRecordYUVBtn.frame = CGRectMake(200, 5*margin, btnW, btnH);
    [self.view addSubview:endRecordYUVBtn];
}

- (NSScrollView *)scrollView//容器视图
{
    if (!_scrollView) {
        _scrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, 400, 200)];
        [_scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
        _scrollView.documentView = self.tableView;
        _scrollView.hasVerticalScroller = YES;
    }
    return _scrollView;
}

- (NSTableView *)tableView
{
    if (!_tableView) {
        _tableView = [[NSTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        [_tableView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
        _tableView.delegate = (id)self;
        _tableView.dataSource = self;
        _tableView.allowsColumnReordering = NO;
        _tableView.allowsColumnResizing = NO;
        _tableView.focusRingType = NSFocusRingTypeNone;
        _tableView.rowHeight = 44;
        _tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
        
        NSTableColumn *firstCol = [[NSTableColumn alloc] initWithIdentifier:@"firstCol"];
        firstCol.width = 200;
        firstCol.title = @"第一列";
        [_tableView addTableColumn:firstCol];
        
        
//        NSTableColumn *secondCol = [[NSTableColumn alloc] initWithIdentifier:@"secondCol"];
//        secondCol.width = self.scrollView.bounds.size.width - 200;
//        secondCol.title = @"第二列";
//        [_tableView addTableColumn:secondCol];
                
    }
    return _tableView;
}

- (void)endRecord:(id)sender
{
    if (recordObj->stopRecord ==  false) {
        recordObj->stopRecord = true;
        self.beiginRecordSwitch.state = NSControlStateValueOn;
    }
}
- (void)beginRecord:(id)sender
{
    _beiginRecordSwitch.state = NSControlStateValueOff;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->recordObj = new JLRecordPCMOrYUV;
        self->recordObj->beginRecordPCM();
        return;
    });
}

- (void)beginPlay:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->playPCMObj = new JLPlayPCM;
        self->playPCMObj->beginPlay();
    });
}

- (void)endPlay:(id)sender
{
    self->playPCMObj->stopPlay = true;
}


- (void)beginConvert:(id)sender
{
    // 封装WAV的头部
    WAVHeader header;
    header.numChannels = 2;
    header.sampleRate = 44100;
    header.bitsPerSample = 32;
    JLPCMToWAV::pcm2wav(header, "/Users/dalong/Desktop/AV/3.pcm", "/Users/dalong/Desktop/AV/7.wav");
}

- (void)beginPlayWAV:(id)sender
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->playWAVObj = new JLPlayWAV;
        self->playWAVObj->beginPlay();
    });
}

- (void)endPlayWAV:(id)sender
{
    self->playWAVObj->stopPlay = true;
}

- (void)audioResample:(id)sender
{
    JLAudioResample::resampleAudio("/Users/dalong/Desktop/AV/44100_s16le_2.pcm", 44100, AV_SAMPLE_FMT_S16, 2, "/Users/dalong/Desktop/AV/48000_f32le_2.pcm", 48000, AV_SAMPLE_FMT_FLT, 2);
}

- (void)aacEncode:(id)sender
{
    AudioEncodeSpec spec = {
        "/Users/dalong/Desktop/AV/44100_s16le_2.pcm",
        44100,
        AV_SAMPLE_FMT_S16,
        AV_CH_LAYOUT_STEREO
    };
    JLAACCodec::aacEncode(spec, "/Users/dalong/Desktop/AV/aacCode.aac");
}

- (void)aacDecode:(id)sender
{
    AudioEncodeSpec spec = {
        "/Users/jl/Downloads/44100_s16le_2_aacDecodeOutput.pcm",
        44100,
        AV_SAMPLE_FMT_S16,
        AV_CH_LAYOUT_STEREO
    };
//    JLAACCodec::aacEncode(spec, "/Users/dalong/Desktop/AV/aacCode.aac");
    JLAACCodec::aacDecode("/Users/jl/Downloads/output.aac", spec);
}

- (void)endRecordYUV:(id)sender
{
    if (recordObj->stopRecord ==  false) {
        recordObj->stopRecord = true;
        self.beiginRecordSwitch.state = NSControlStateValueOn;
    }
}
- (void)beginRecordYUV:(id)sender
{
    _beiginRecordSwitch.state = NSControlStateValueOff;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->recordObj = new JLRecordPCMOrYUV;
        self->recordObj->beginRecordYUV();
        return;
    });
}

#pragma mark - action

- (void)play:(NSButton *)sender
{
    [_osPlayer play];
}

- (void)stop
{
    [_osPlayer pause];
}

- (void)draw {
    if (self.playView.stop) {
        
        self.playView.stop = NO;
        NSLog(@"结束了。");
        return;
    }
    
//    NSLog(@"%@",[NSData dataWithBytes:buf length:yuv_length]);
    
//    _playView.drawBlock = ^{
//        size_t yuv_length = yuv_width*yuv_height*3/2;
//        Byte buf[yuv_length];
//        fread(buf, 1, yuv_length, file);
//        int isEnd = feof(file);
//        if (isEnd > 0) {
//            fseek(file, 0, SEEK_SET);
//        }
//        [self.playView displayYUV_I420:(char*)buf width:yuv_width height:yuv_height];
//
//    };
    
//    size_t yuv_length = yuv_width*yuv_height*3/2;
//    Byte buf[yuv_length];
//    fread(buf, 1, yuv_length, file);
//    if (feof(file) > 0) {
//        self.playView.stop = YES;
//        fseek(file, 0, SEEK_SET);
//    }
//    [self.playView displayYUV_I420:(char*)buf width:yuv_width height:yuv_height];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self draw];
//    });
}


@end
