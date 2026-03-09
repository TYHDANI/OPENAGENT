# Video Ads Production Guide — OPENAGENT

## Quick Reference: 3 Video Generation Methods

### Method 1: Seedance 2.0 (AI-Generated Cinematic Video)
**Best for**: App Store previews, cinematic ads, product demos
**Access**: jimeng.jianying.com (ByteDance) or cyberbara.com/seedance2.0
**Cost**: Free credits on Jianying platform

**Specs**:
- Up to 9 images + 3 videos + 3 audio files as input
- 4-15 second output, native 2K resolution
- Native sound effects and music generation
- 12 files max per generation

**@ Reference System**:
```
@Image1 — assign as character/product
@Image2 — assign as environment/setting
@Video1 — reference for camera movement
@Audio1 — reference for rhythm/music
```

**Pro Tips**:
1. Use 2K+ source images (blurry input = blurry output)
2. Be explicit: "reference @Video1's camera movement" > just mentioning the file
3. Combine video + image: "@Image1 performs action from @Video1"
4. Iterate small — change one word, not the whole prompt
5. Specify edit vs reference clearly

### Method 2: Remotion (Programmatic Motion Graphics)
**Best for**: Launch videos, feature reels, branded content
**Access**: Open-source JS library (npm install remotion)
**Cost**: Free (self-hosted)

**Workflow**:
1. Agent writes Remotion composition (React components)
2. FireCrawl scrapes brand assets (colors, logos)
3. Renders video frames programmatically
4. Exports H264/MP4

**Integration**: The Launch agent (Phase 11) uses auto_publish.sh to render and distribute.

### Method 3: UGC Script Templates (Human/AI Actor)
**Best for**: TikTok, Instagram Reels, authentic social ads
**Cost**: $0 if using AI avatar, $50-200 if hiring UGC creator

**Framework**: Curiosity Hook → Credibility → Loop Structure → Payoff

## Seedance 2.0 Prompt Templates by App Category

### Health/Wellness Apps
```
Style: Clean medical aesthetic, soft natural lighting
Duration: 15s, Aspect: 9:16

[00-03s] Close-up of person looking at phone with concerned expression.
Warm morning light through window. Slight camera push-in.
[03-08s] Phone screen shows @Image1 (app dashboard). Finger taps through
health metrics. Smooth animations on screen. Data visualizations pulse gently.
[08-12s] Person smiles, relieved. Camera pulls back to show full scene —
organized, calm environment. @Image2 shows key health insight on screen.
[12-15s] App icon @Image3 appears center frame. "Your Health, Simplified"
text fades in. App Store download badge. Soft sound design.
```

### Finance/Trading Apps
```
Style: Dark premium fintech, neon accents on dark UI
Duration: 15s, Aspect: 9:16

[00-03s] Split-second montage: stock ticker, candlestick chart flash,
notification ping. Creates urgency. Dark background with green accent.
[03-08s] Device shows @Image1 (portfolio view). Numbers animate upward.
Real-time chart draws across screen. Finger swipes to @Image2 (analysis).
[08-12s] Pull back — person at desk, multiple screens. Professional setup.
App notification shows "+12.4% this week". Satisfying sound effect.
[12-15s] App icon centered. "Trade Smarter" tagline. Download badge.
Premium dark gradient background.
```

### Productivity/Utility Apps
```
Style: Minimal, Apple-esque white space, gentle animations
Duration: 15s, Aspect: 9:16

[00-03s] Overhead shot of messy desk / chaotic notifications.
Slight shake camera. Stress implied. Quick cuts.
[03-08s] @Image1 appears — app interface, clean and organized.
Smooth transition from chaos to order. Satisfying sorting animation.
Each item finds its place. Reference @Video1 camera tracking.
[08-12s] Productivity stats appear: "3 hours saved this week".
Counter animates up. Person leans back, satisfied.
[12-15s] App icon + tagline + download badge. Clean white fade.
```

### HVAC/Home Apps
```
Style: Warm residential, comfortable, family-friendly
Duration: 15s, Aspect: 9:16

[00-03s] Thermostat display showing high energy bill. Worried expression.
Close-up of rising numbers. Dramatic but relatable.
[03-08s] Hands open @Image1 (app). Dashboard shows energy analysis.
AI recommendations appear one by one. Savings calculator animates.
[08-12s] Split screen: before (high bill) vs after (optimized).
Green savings number grows. House feels comfortable. Smart home feel.
[12-15s] App icon + "Save $200/year on energy" + download badge.
```

## UGC Ad Script Templates

### Template A: "Nobody Tells You" Hook
```
HOOK (0-2s): "Nobody tells you this about [domain]..."
CREDIBILITY (2-4s): "I've been [relevant experience] for [time]..."
INSIGHT (4-8s): "[Non-obvious fact]. [Explain why]. [Make it relatable]."
BRIDGE (8-10s): "That's exactly why I built [App Name]."
DEMO (10-13s): [Quick screen recording of key feature]
CTA (13-15s): "Link in bio. It's free to try."
```

### Template B: "I Was Spending $X" Hook
```
HOOK (0-2s): "I was spending [amount] on [pain point]..."
PIVOT (2-5s): "Until I realized [insight about the problem]."
SOLUTION (5-9s): "So I [built/found] [App Name] that [key benefit]."
PROOF (9-13s): [Show results — savings, time saved, improvement]
CTA (13-15s): "Download free. Seriously, it changed everything."
```

### Template C: "As A [Professional]" Hook
```
HOOK (0-2s): "As a [job title], I see [specific problem] every day."
INSIGHT (2-5s): "[Data point about the problem]. Most people don't know."
REVEAL (5-9s): "That's why [App Name] exists. It [key differentiator]."
DEMO (9-13s): [Quick walkthrough of 2-3 features]
CTA (13-15s): "Try it free. Your [outcome] will thank you."
```

## Remotion Integration Notes

Remotion compositions are React components that render video frames:

```javascript
// Example Remotion composition structure
export const LaunchVideo = () => {
  return (
    <Composition
      id="LaunchVideo"
      component={MainVideo}
      durationInFrames={30 * 45} // 45 seconds at 30fps
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
```

**Rendering**: `npx remotion render src/index.tsx LaunchVideo out/launch.mp4`

**FireCrawl Integration**: Scrapes brand assets (colors, logos, fonts) from the app's website or App Store listing to maintain brand consistency automatically.

## Audio Integration

### 11 Labs (ElevenLabs) for Voiceover
- Generate natural voiceover for ad narration
- Multiple voice styles (professional, casual, energetic)
- Multi-language support for localization

### Seedance Native Audio
- Generates environmental sounds matched to visuals
- Lip-sync for character dialogue
- Beat-synced background music

### Free Music Sources
- YouTube Audio Library (royalty-free)
- Pixabay Music
- Uppbeat (free tier)
