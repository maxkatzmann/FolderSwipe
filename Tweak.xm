@interface SBIcon
- (BOOL)isFolderIcon;
@end

@interface SBFolderIcon : SBIcon
- (void)launch;
@end

@interface SBFolderIconView : UIView

- (void)setFrame:(struct CGRect)arg1;
- (void)setHighlighted:(BOOL)arg1;
- (void)_updateIconBrightness;
- (void)longPressTimerFired;

@end

@interface SBFolderIconView (FolderSwipe)

static BOOL FSallowJitter = YES;
- (void)FShandleSwipe:(UISwipeGestureRecognizer *)gesture;
- (void)FSsetAllowJitter:(BOOL)permission;

@end

%hook SBFolderIconView

- (void)setFrame:(struct CGRect)arg1 {

    UISwipeGestureRecognizer *swipeRec = [[[%c(UISwipeGestureRecognizer) alloc] initWithTarget:self action:@selector(FShandleSwipe:)] autorelease];
    swipeRec.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    [self addGestureRecognizer:swipeRec];

    %orig;
}

/*
this method will make the icons on the SpringBoard jitter
and unfortunately gets called, when we swipe open the folder
*/
- (void)longPressTimerFired {
    if (FSallowJitter) {
        %orig;
    } else {
        [self FSsetAllowJitter:YES];
    }
}

%new
- (void)FShandleSwipe:(UISwipeGestureRecognizer *)gesture {

    SBIcon *icon = MSHookIvar<id>(self, "_icon");

    /*
    since the recognizer will only be added to an SBFolderIconView
    the icon should be a folder (just making sure..)
    */
    if ([icon isFolderIcon]) {
        [(SBFolderIcon *)icon launch]; //open the folder
        [self setHighlighted:NO]; //when tapped, an icon gets dark we want to unselect it
        [self _updateIconBrightness]; //then update its brightness taking into account that the icon is no longer selected
        [self FSsetAllowJitter:NO]; //the swipe will make the folder think it gets longPressed (but we don't want our icons to start jittering)
    }
}

%new
- (void)FSsetAllowJitter:(BOOL)permission {
    FSallowJitter = permission;
}

%end