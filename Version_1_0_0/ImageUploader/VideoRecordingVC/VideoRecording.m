//
//  HomeViewController.m
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 29/10/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//[25.10.17, 19:55:14] Ashot:// baggi24@mail.ru
//boomer2017memo
//[25.10.17, 19:55:22] Ashot: boomer2017memo

#import "VideoRecording.h"
#import "ViewUtils.h"
#import "LLSimpleCamera.h"
#import "ResponseViewController.h"
#import "ResivedModel.h"
#import <FCAlertView/FCAlertView.h>


@interface VideoRecording ()<LLSimpleCameraDelegate, CAAnimationDelegate>
@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *useVideoButton;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) UIView* scanerView;
@property ()int imageCounter;
@property () BOOL isCanceled;
@property () BOOL isStoped ;



@property () UIView *coverView;
@property()NSMutableArray* rectArry;
@property()NSMutableArray* boolArry;

@property () UIImage* uploadedImage;
@property () NSMutableArray* images;


@end

@implementation VideoRecording

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.rectArry = [[NSMutableArray alloc]init];
    self.boolArry = [[NSMutableArray alloc]init];
    self.images = [[NSMutableArray alloc]init];
    
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)control
{
    NSLog(@"Segment value changed!");
}

-(void)setupCamera {
    
    self.isCanceled = NO;
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    _imageCounter = 0;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPreset1280x720
                                                 position:LLCameraPositionRear
                                             videoEnabled:YES];
    
    self.camera.imageCaptureDelegate = self;
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = self.snapButton.width / 2.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.snapButton setEnabled:YES];
    [self.view addSubview:self.snapButton];
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(12.0f, screenRect.size.height - 67.0f, 120.0f, 32.0f);
    self.cancelButton.backgroundColor = [UIColor clearColor];
    self.cancelButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.cancelButton.layer.borderWidth = 1.f;
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //  [self.cancelButton setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    self.cancelButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelButton];
    
    self.resiveLabel = [[UILabel alloc]initWithFrame:CGRectMake(12.0f, screenRect.size.height - 75.0f, 120.0f, 32.0f)];
    self.resiveLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.resiveLabel];
    
    self.sendLabel = [[UILabel alloc]initWithFrame:CGRectMake(12.0f, screenRect.size.height - 90.0f, 120.0f, 32.0f)];
    self.sendLabel.textColor = [UIColor greenColor];
    [self.view addSubview:self.sendLabel];
    
    self.useVideoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.useVideoButton.frame = CGRectMake(screenRect.size.width - 130.f, screenRect.size.height - 67.0f, 120.0f, 32.0f);
    self.useVideoButton.tintColor = [UIColor whiteColor];
    self.useVideoButton.backgroundColor = [UIColor clearColor];
    self.useVideoButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.useVideoButton.layer.borderWidth = 1.f;
    [self.useVideoButton setTitle:@"Use Video" forState:UIControlStateNormal];
    [self.useVideoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.useVideoButton setHidden:YES];
    // [self.useVideoButton setImage:[UIImage imageNamed:@"camera-flash"] forState:UIControlStateNormal];
    self.useVideoButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.useVideoButton addTarget:self action:@selector(useVideoPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.useVideoButton];
    
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.switchButton];
    }
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Cancel",@"Use video"]];
    self.segmentedControl.frame = CGRectMake(12.0f, screenRect.size.height - 67.0f, 120.0f, 32.0f);
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.tintColor = [UIColor whiteColor];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    //[self.view addSubview:self.segmentedControl];
    
    // start the camera
    [self.camera startCam];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupCamera];
    [self scanView];
    self.isStoped = true;
    self.imageSuccesFuluCaptured = ^(NSString *param){
        FCAlertView *alert = [[FCAlertView alloc]init];
        [alert showAlertWithTitle:@"Success"
                     withSubtitle:@"Image Successfuly detected"
                  withCustomImage:[UIImage imageNamed:@"checkbox"]
              withDoneButtonTitle:@"Ok"
                       andButtons:nil];
        [self.navigationController popViewControllerAnimated:false];
    };
    
    
    
    __weak typeof(self) weakSelf = self;
    self.imageNotDetected = ^(NSString *param){
        [weakSelf stopCapturing];
        weakSelf.isCanceled = YES;
        
        FCAlertView *alert = [[FCAlertView alloc]init];
        [alert showAlertWithTitle:@"No similar object detected"
                     withSubtitle:@""
                  withCustomImage:[UIImage imageNamed:@"failure"]
              withDoneButtonTitle:@"Ok"
                       andButtons:nil];
        [alert doneActionBlock:^{
            [weakSelf.navigationController popToRootViewControllerAnimated:true];
        }];
    };
    
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    
}


-(void)scanView {
    
    self.scanerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 7)];
    self.scanerView.backgroundColor = [UIColor redColor];
    
    
}

-(void)addScanAnimation {
    [self.view addSubview:self.scanerView];
    CGPoint start = CGPointMake(self.view.frame.size.width/2, 0);
    CGPoint end = CGPointMake(self.view.frame.size.width/2, self.snapButton.frame.origin.y);
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.delegate = self;
    animation.fromValue = [NSValue valueWithCGPoint:start];
    animation.toValue = [NSValue valueWithCGPoint:end];
    animation.duration = 5;
    
    animation.repeatCount = 100;
    animation.autoreverses = YES;
    animation.removedOnCompletion   = YES;
    animation.fillMode = kCAFillModeForwards;
    [self.scanerView.layer addAnimation:animation forKey:@"position"];
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if (self.scanerView != nil){
        [self.scanerView.layer removeAllAnimations];
        self.scanerView.frame = CGRectMake(0, 0, self.view.frame.size.width, 7);
        [self addScanAnimation];
    }
    
}
/* camera button methods */

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

-(void)cancelButtonPressed:(UIButton *)button {
    [self stopCapturing];
    self.isCanceled = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
   // [self.navigationController popToRootViewControllerAnimated:true];
    //self.recordCancelBlock();
}

-(void)useVideoPressed:(UIButton *)button {
    if (self.videoURL != nil) {
        self.recordFinishedBlock(self.videoURL,self.images.lastObject);
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)stopCapturing {
    [self.camera stop];
}


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera flashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera flashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    
            if(!self.camera.isRecording) {
                self.segmentedControl.hidden = YES;
                self.flashButton.hidden = YES;
                self.switchButton.hidden = YES;
                [self.useVideoButton setHidden:YES];
                self.snapButton.layer.borderColor = [UIColor redColor].CGColor;
                self.snapButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
    
                // start recording
                NSURL *outputURL = [[[self applicationDocumentsDirectory]
                                     URLByAppendingPathComponent:@"test1"] URLByAppendingPathExtension:@"mov"];
    
    
                [self.camera startRecordingWithOutputUrl:outputURL didRecord:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
                    NSLog(@"outputFileUrl = %@",outputFileUrl);
                    self.videoURL = outputFileUrl;
                    self.useVideoButton.enabled = YES;
    
    
                }];
    
    
            } else {
                [self setupCamera];
                self.segmentedControl.hidden = NO;
                self.flashButton.hidden = NO;
                self.switchButton.hidden = NO;
    
                self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
                self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    
                [self.camera stopRecording];
                [self.useVideoButton setHidden:NO];
            }
    
    
    //[self performSelector:@selector(showAlert) withObject:nil afterDelay:3];
}

-(void)showAlert {
    [self showDetectedAlert:[UIImage imageNamed:@"checkbox"] responsImage:[UIImage imageNamed:@"checkbox"] responsObject:@"Hello"];
}

/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.bottom = self.view.height - 15.0f;
    
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
    
    self.segmentedControl.left = 12.0f;
    self.segmentedControl.bottom = self.view.height - 35.0f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)capturedImage:(UIImage *)image {
   // if(!self.isStoped){
        _imageCounter++;
        if (_imageCounter == 5) {
            //if (self.imageCapturedBlock){
                UIImage* img = [self imageWithImage:image convertToSize:CGSizeMake(image.size.width / 2, image.size.height / 2)];
                [self.images addObject:img];
                //self.imageCapturedBlock(img);
                _imageCounter = 0;
           // }
            
        }
   // }
}

-(void) capturedImageData:(NSData *)imageData {
    
}



- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

-(void) drowRect:(CGRect)rect andStatus:(bool)isGood{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIColor *color = isGood ? [UIColor greenColor] : [UIColor redColor];
        if (_rectView != nil) {
            if (rect.size.height == 0 && rect.size.width == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _rectView.layer.borderColor = [UIColor clearColor].CGColor;
                });
            }
            if(self.rectArry.count > 3) {
                [self.rectArry removeObjectAtIndex:0];
                [self.boolArry removeObjectAtIndex:0];
            }
            NSString* rectAsString = NSStringFromCGRect( rect );
            [self.rectArry addObject:rectAsString];
            NSNumber *num = [[NSNumber alloc]initWithBool:isGood];
            [self.boolArry addObject:num];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rectView.frame = rect;
                [self.view bringSubviewToFront:self.cancelButton];
                [self.view bringSubviewToFront:self.snapButton];
                _rectView.layer.borderColor = color.CGColor;
            });
            CGRect newRect = [self getMidle:self.rectArry];
            //            if(fabs(newRect.origin.x - rect.origin.x) <= 7 && fabs(newRect.origin.y - rect.origin.y)<= 7 &&
            //               fabs(newRect.origin.x + newRect.size.width - rect.origin.x -rect.size.width) <= 7 && fabs(newRect.origin.y + newRect.size.height - rect.origin.y - rect.size.height)<= 7) {
            //                bool good = [self getRectQuality:self.boolArry];
            //                UIColor *colorNew = good ? [UIColor greenColor] : [UIColor redColor];
            //
            //                dispatch_async(dispatch_get_main_queue(), ^{
            //                    self.rectView.frame = newRect;
            //                    [self.view bringSubviewToFront:self.cancelButton];
            //                    [self.view bringSubviewToFront:self.snapButton];
            //                    _rectView.layer.borderColor = colorNew.CGColor;
            //                    NSLog(@"Nkarec");
            //                });
            //            } else {
            //                dispatch_async(dispatch_get_main_queue(), ^{
            //                    _rectView.layer.borderColor = [UIColor clearColor].CGColor;
            //                });
            //            }
            
        } else {
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rectView = [[UIView alloc]initWithFrame:rect];
                _rectView.layer.borderColor = color.CGColor;
                _rectView.layer.borderWidth = 1.f;
                [self.view addSubview:_rectView];
                
                self.cancelButton.layer.zPosition = 1;
                [self.view bringSubviewToFront:self.cancelButton];
                [self.view bringSubviewToFront:self.snapButton];
            });
            
            
        }
        
    });
    
}




-(CGRect)getMidle:(NSArray *)rectsArray {
    double xPos = 0;
    double yPos = 0;
    double width = 0;
    double height = 0;
    
    for (int i = 0; i<rectsArray.count; i++) {
        NSString *rectAsString = [rectsArray objectAtIndex:i];
        CGRect rect = CGRectFromString( rectAsString);
        xPos += rect.origin.x;
        yPos += rect.origin.y;
        width += rect.size.width;
        height += rect.size.height;
    }
    CGRect newRect = CGRectMake(xPos/rectsArray.count, yPos/rectsArray.count, width/rectsArray.count, height/rectsArray.count);
    
    return newRect;
}

-(bool)getRectQuality:(NSArray *)boolArray {
    int counter = 0;
    for(NSNumber * num in boolArray){
        if(num.boolValue){
            counter++;
            return YES;
        }
    }
    //    if (counter >1){
    //        return YES;
    //    }
    return NO;
}

-(void)showDetectedAlert:(UIImage*)uploadedImage responsImage:(UIImage*)responsImg responsObject:(NSString*)responsObj{
    [ResivedModel sharedInstance].resivedImage = [ResivedModel sharedInstance].uploadedImage;
    [ResivedModel sharedInstance].resivedObject = responsObj;
    
    //[self performSegueWithIdentifier:@"showResponsVC" sender:nil];
}




-(void)drow:(NSArray*)points {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGRect screen  = UIScreen.mainScreen.bounds;
        UIColor *color = [UIColor greenColor];
        double xDif = screen.size.width;
        double yDif = screen.size.height;
        
        if (self.rectArry.count == 17 ){
            for (int i = 0; i<points.count; i += 2) {
                NSLog(@"points count = %d",points.count);
                NSLog(@"i = %d",i);
                NSNumber* num1 = points[i];
                NSNumber* num2 = points[i+1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ((UIView*)[self.rectArry objectAtIndex:i/2]).center = CGPointMake(num1.floatValue * xDif , num2.floatValue * yDif);
                });
            }
        }else {
            
            
            for (int i = 0; i<points.count; i += 2) {
                NSNumber* num1 = points[i];
                NSNumber* num2 = points[i+1];
                UIView *pointView = [[UIView alloc]initWithFrame: CGRectMake(num1.floatValue * xDif , num2.floatValue * yDif, 7, 7)];
                pointView.layer.backgroundColor = color.CGColor;
                pointView.layer.borderWidth = 1.f;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (pointView.frame.origin.x != 0 || pointView.frame.origin.y != 0) {
                        [self.view addSubview:pointView];
                    }
                    [self.rectArry addObject:pointView];
                });
            }
        }
        
        
        
    });
    
    
    
}

-(void)stopUploading {
    [self stopCapturing];
    self.isCanceled = YES;
    self.isStoped = true;
}
@end