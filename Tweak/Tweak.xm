#import <Cephei/HBPreferences.h>

static NSDictionary *prefixes = @{
    @"furry": @[@"", @"", @""]
};

static NSDictionary *suffixes = @{
    @"furry": @[@"", @"", @""]
};

static NSDictionary *replacement = @{

    @"alternate": @{
        @"fuck": @"fork",
        @"ass": @"ask",
        @"damn": @"dam",
        @"shit": @"shot",
        @"fucking": @"forking",

    },
    @"dashes": @{
        @"fuck": @"f---",
        @"ass": @"a--",
        @"damn": @"d---",
        @"shit": @"sh--",
        @"fucking": @"f---ing",
    }
};

static NSString *mode = nil;

NSString *owoify (NSString *text, bool replacementOnly) {
    NSString *temp = [text copy];
    
    if (replacement[mode]) {
        for (NSString *key in replacement[mode]) {
            temp = [temp stringByReplacingOccurrencesOfString:key withString:replacement[mode][key]];
        }
    }

    if (replacementOnly) return temp;

    if (prefixes[mode]) {
        temp = [prefixes[mode][arc4random() % [prefixes[mode] count]] stringByAppendingString:temp];
    }

    if (suffixes[mode]) {
        temp = [temp stringByAppendingString:suffixes[mode][arc4random() % [suffixes[mode] count]]];
    }

    return temp;
}

%group BlockifyNotifications

%hook NCNotificationContentView

-(void)setPrimaryText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, true));
}

-(void)setSecondaryText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, false));
}

%end

%end

%group BlockifyEverywhere

%hook UILabel

-(void)setText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, true));
}

%end

%hook T1StatusAttributedTextView

-(void)setText:(NSString *)orig {
    if (!orig) {
        %orig(orig);
        return;
    }
    
    %orig(owoify(orig, true));
}

%end


%end

%group BlockifyIconLabels

%hook SBIconLabelImageParameters

-(NSString *)text {
    return owoify(%orig, true);
}

%end

%end

%group BlockifySettings

%hook PSSpecifier

-(NSString *)name {
    return owoify(%orig, true);
}

%end

%end

%ctor {
    if (![NSProcessInfo processInfo]) return;
    NSString *processName = [NSProcessInfo processInfo].processName;
    bool isSpringboard = [@"SpringBoard" isEqualToString:processName];

    bool shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                        || [processName isEqualToString:@"CoreAuthUI"]
                        || [processName isEqualToString:@"InCallService"]
                        || [processName isEqualToString:@"MessagesNotificationViewService"]
                        || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if ((!isFileProvider && isApplication && !skip) || isSpringboard) {
                shouldLoad = YES;
            }
        }
    }

    if (!shouldLoad) return;

    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"com.cooper.blockify"];

    if ([([file objectForKey:@"Enabled"] ?: @(YES)) boolValue]) {
        mode = [file objectForKey:@"Style"] ?: @"dashes";

        if ([([file objectForKey:@"EnabledEverywhere"] ?: @(YES)) boolValue]) {
            %init(BlockifyEverywhere);
        }

        if ([([file objectForKey:@"EnabledSettings"] ?: @(YES)) boolValue]) {
            %init(BlockifySettings);
        }

        if (isSpringboard) {
            if ([([file objectForKey:@"EnabledNotifications"] ?: @(YES)) boolValue]) {
                %init(BlockifyNotifications);
            }

            if ([([file objectForKey:@"EnabledIconLabels"] ?: @(YES)) boolValue]) {
                %init(BlockifyIconLabels);
            }
        }
    }
}
