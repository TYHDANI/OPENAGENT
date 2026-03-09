#!/bin/bash
# OPENAGENT Video Ads Generator — Phase 10 Integration
# Generates video ad assets using Seedance 2.0 prompts, UGC scripts, and Remotion specs
# Sources: awesome-seedance, UGC Ads Method PDF, OpenClaw Motion Graphics PDF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Generate Seedance 2.0 prompt for App Store preview video
# Usage: generate_seedance_prompt "project_dir" "app_name" "app_category"
generate_seedance_prompt() {
    local project_dir="$1"
    local app_name="$2"
    local category="$3"

    echo "Generating Seedance 2.0 prompt for $app_name ($category)..."

    mkdir -p "$project_dir/promo/videos"

    python3 -c "
import json, os

category = '$category'
app_name = '$app_name'

# Category-specific style presets
styles = {
    'health': {
        'aesthetic': 'Clean medical, soft natural lighting',
        'colors': 'White space with calming blue/green accents',
        'mood': 'Reassuring, trustworthy, empowering',
        'hook': 'Close-up of person checking phone with concerned expression'
    },
    'finance': {
        'aesthetic': 'Dark premium fintech, neon on dark UI',
        'colors': 'Dark background with green/gold accent neon',
        'mood': 'Professional, powerful, data-driven',
        'hook': 'Split-second montage: ticker, candlestick, notification ping'
    },
    'productivity': {
        'aesthetic': 'Minimal Apple-esque, white space, gentle animations',
        'colors': 'Clean white with single brand accent color',
        'mood': 'Calm, organized, satisfying',
        'hook': 'Overhead shot of messy desk / chaotic notifications'
    },
    'hvac': {
        'aesthetic': 'Warm residential, comfortable, family-friendly',
        'colors': 'Warm tones, green energy accents',
        'mood': 'Comfortable, smart, money-saving',
        'hook': 'Thermostat display showing high energy bill'
    },
    'survival': {
        'aesthetic': 'Rugged outdoor, dramatic landscapes',
        'colors': 'Earth tones with emergency orange/red accents',
        'mood': 'Urgent, prepared, adventurous',
        'hook': 'Dramatic landscape shot, weather changing rapidly'
    },
    'dao': {
        'aesthetic': 'Futuristic blockchain, dark with bio-glow',
        'colors': 'Deep navy with vibrant green/cyan data accents',
        'mood': 'Innovative, secure, community-powered',
        'hook': 'Abstract data particles forming a shield shape'
    }
}

style = styles.get(category, styles['productivity'])

prompt_data = {
    'app_name': app_name,
    'category': category,
    'seedance_prompts': {
        'app_store_preview': {
            'model': 'Seedance 2.0',
            'duration': '15s',
            'aspect_ratio': '9:16 (portrait) or 16:9 (landscape)',
            'resolution': '2K native',
            'style': style['aesthetic'],
            'prompt': f'''Style: {style['aesthetic']}
Duration: 15s

[00-03s] HOOK: {style['hook']}.
Camera: Slight push-in. Shallow depth of field.
Mood: {style['mood']}.

[03-08s] DEMO: Hand holds iPhone showing @Image1 (main app screen).
Finger interacts with key feature. Smooth UI animations visible on screen.
Data/content updates in real-time. Natural gesture — tap, swipe, scroll.
Camera: Gentle tracking following the hand.

[08-12s] BENEFIT: Pull back to show context.
@Image2 displays the key result/insight.
Satisfying visual: numbers animate, graph draws, content organizes.
Emotional beat: relief, satisfaction, empowerment.

[12-15s] CTA: App icon @Image3 centered.
\"{app_name}\" text fades in with tagline.
App Store download badge appears.
Subtle sound design — success chime.''',
            'reference_files': {
                '@Image1': 'screenshots/main_screen.png (2K+)',
                '@Image2': 'screenshots/key_feature.png (2K+)',
                '@Image3': 'app_icon_1024.png',
                '@Video1': '(optional) reference video for camera style',
                '@Audio1': '(optional) 15s background track'
            },
            'pro_tips': [
                'Use 2K+ source images — blurry input = blurry output',
                'Be explicit: reference @Video1 camera movement > just mentioning file',
                'Iterate small changes, not full prompt rewrites',
                'Specify edit vs reference clearly'
            ]
        },
        'tiktok_ad': {
            'duration': '15s',
            'aspect_ratio': '9:16',
            'prompt': f'''Style: UGC authentic, iPhone front camera feel
Duration: 15s

[00-02s] Person looks into camera. Natural lighting. Slight head tilt.
\"Nobody tells you this about {category}...\"

[02-06s] Quick cut to phone screen showing @Image1.
Finger scrolls through features. Fast-paced, no dead space.

[06-12s] Back to person. Animated, gesturing.
\"This completely changed how I [relevant action].\"
Cut between face and phone demo. Rapid edits.

[12-15s] Screen shows @Image2 (results).
Text overlay: \"Link in bio\" with pointing animation.
'''
        }
    }
}

output_path = os.path.join('$project_dir', 'promo', 'videos', 'seedance_prompts.json')
with open(output_path, 'w') as f:
    json.dump(prompt_data, f, indent=2)

print(f'Seedance prompts saved to {output_path}')
print(f'Category: {category} | Style: {style[\"aesthetic\"]}')
" 2>/dev/null
}

# Generate UGC ad scripts using the viral hook framework
# Usage: generate_ugc_scripts "project_dir" "app_name" "key_benefit" "target_audience"
generate_ugc_scripts() {
    local project_dir="$1"
    local app_name="$2"
    local benefit="$3"
    local audience="$4"

    echo "Generating UGC ad scripts for $app_name..."

    mkdir -p "$project_dir/promo/videos"

    python3 -c "
import json, os

app_name = '$app_name'
benefit = '$benefit'
audience = '$audience'

scripts = {
    'ugc_scripts': [
        {
            'id': 'nobody_tells_you',
            'hook_type': 'curiosity',
            'duration': 15,
            'aspect_ratio': '9:16',
            'script': {
                'hook_0_2s': f'Nobody tells you this about {audience.split()[0] if audience else \"your\"}...',
                'credibility_2_4s': f'I\\'ve been dealing with this for years and finally found something.',
                'insight_4_8s': f'[Non-obvious fact about the domain]. Most people waste time/money because they don\\'t know this.',
                'bridge_8_10s': f'That\\'s exactly why {app_name} exists.',
                'demo_10_13s': f'[Screen recording: open app -> key feature -> result in 3 taps]',
                'cta_13_15s': 'Link in bio. Free to try. Seriously.'
            },
            'notes': 'Trim ALL dead space between lines. Maximum pace. Close/open loops constantly.',
            'filming_tips': 'iPhone front camera, natural daylight, slightly off-center framing'
        },
        {
            'id': 'spending_too_much',
            'hook_type': 'problem_aware',
            'duration': 15,
            'aspect_ratio': '9:16',
            'script': {
                'hook_0_2s': f'I was wasting so much time on [pain point]...',
                'pivot_2_5s': f'Until I realized {benefit}.',
                'solution_5_9s': f'{app_name} does this automatically. Watch.',
                'proof_9_13s': '[Show results — savings, time saved, improvement metric]',
                'cta_13_15s': 'Download free. Changed everything for me.'
            },
            'notes': 'Personal, vulnerable opening. Show real transformation.',
            'filming_tips': 'Start frustrated/overwhelmed, end relieved/happy'
        },
        {
            'id': 'as_a_professional',
            'hook_type': 'authority',
            'duration': 15,
            'aspect_ratio': '9:16',
            'script': {
                'hook_0_2s': f'As someone who works with {audience} every day...',
                'insight_2_5s': '[Specific data point about the problem]. Most people have no idea.',
                'reveal_5_9s': f'{app_name} fixes this. [Key differentiator explained simply].',
                'demo_9_13s': '[Quick walkthrough of 2-3 features, rapid cuts]',
                'cta_13_15s': f'Try {app_name} free. Your future self will thank you.'
            },
            'notes': 'Authority builds trust fast. Data point must be surprising/non-obvious.',
            'filming_tips': 'Professional but approachable. Office or relevant environment.'
        },
        {
            'id': 'before_after',
            'hook_type': 'transformation',
            'duration': 15,
            'aspect_ratio': '9:16',
            'script': {
                'hook_0_3s': 'POV: Before vs After [domain]',
                'before_3_7s': '[Show the messy/stressful/expensive before state]',
                'transition_7_8s': '[Satisfying transition — swipe, snap, morph]',
                'after_8_13s': f'[Show clean/organized/profitable state with {app_name}]',
                'cta_13_15s': f'{app_name}. Free download. Link in bio.'
            },
            'notes': 'Visual contrast is everything. Make the before genuinely bad.',
            'filming_tips': 'Split screen or sharp cut transition. High contrast.'
        },
        {
            'id': 'social_proof',
            'hook_type': 'social_proof',
            'duration': 15,
            'aspect_ratio': '9:16',
            'script': {
                'hook_0_2s': 'This app has been blowing up and I finally tried it...',
                'context_2_5s': f'Everyone\\'s been talking about {app_name} so I downloaded it.',
                'demo_5_11s': '[First-time user experience. Genuine reactions. Quick feature tour]',
                'verdict_11_13s': 'Okay yeah I get the hype now. This is actually insane.',
                'cta_13_15s': 'Go download it. Trust me.'
            },
            'notes': 'Authentic first-impression feel. Genuine surprise reactions.',
            'filming_tips': 'Casual, unscripted feel. Real-time discovery vibe.'
        }
    ]
}

output_path = os.path.join('$project_dir', 'promo', 'videos', 'ugc_ad_scripts.json')
with open(output_path, 'w') as f:
    json.dump(scripts, f, indent=2)

print(f'Generated {len(scripts[\"ugc_scripts\"])} UGC ad scripts for {app_name}')
" 2>/dev/null
}

# Generate Remotion motion graphics specification
# Usage: generate_remotion_spec "project_dir" "app_name" "primary_color" "tagline"
generate_remotion_spec() {
    local project_dir="$1"
    local app_name="$2"
    local primary_color="$3"
    local tagline="$4"

    echo "Generating Remotion motion graphics spec for $app_name..."

    mkdir -p "$project_dir/promo/videos"

    python3 -c "
import json, os

spec = {
    'title': '$app_name Launch Video',
    'duration_seconds': 45,
    'fps': 30,
    'resolution': {'width': 1920, 'height': 1080},
    'brand': {
        'primary_color': '$primary_color',
        'font': 'SF Pro Display',
        'logo_path': 'promo/assets/logo.png',
        'app_name': '$app_name',
        'tagline': '$tagline'
    },
    'sequences': [
        {
            'id': 1, 'name': 'hero_intro', 'duration': 5,
            'type': 'text_reveal',
            'content': {'headline': 'Introducing $app_name', 'subtitle': '$tagline'},
            'animation': 'fade_scale_up',
            'background': 'gradient_brand'
        },
        {
            'id': 2, 'name': 'problem_statement', 'duration': 5,
            'type': 'text_animation',
            'content': {'text': '[Problem statement with animated emphasis]'},
            'animation': 'typewriter_with_highlight'
        },
        {
            'id': 3, 'name': 'feature_1', 'duration': 8,
            'type': 'device_mockup',
            'content': {'screenshot': 'promo/assets/screen1.png', 'label': 'Feature 1'},
            'animation': 'iphone_3d_rotate_in',
            'interaction': 'simulated_tap_scroll'
        },
        {
            'id': 4, 'name': 'feature_2', 'duration': 8,
            'type': 'device_mockup',
            'content': {'screenshot': 'promo/assets/screen2.png', 'label': 'Feature 2'},
            'animation': 'slide_in_from_right',
            'interaction': 'simulated_swipe'
        },
        {
            'id': 5, 'name': 'stats', 'duration': 7,
            'type': 'stats_counter',
            'content': {
                'stats': [
                    {'label': 'Features', 'value': '20+', 'icon': 'sparkles'},
                    {'label': 'Rating', 'value': '4.9', 'icon': 'star.fill'},
                    {'label': 'Free Trial', 'value': '7 days', 'icon': 'gift'}
                ]
            },
            'animation': 'stagger_count_up'
        },
        {
            'id': 6, 'name': 'testimonial', 'duration': 5,
            'type': 'quote_card',
            'content': {'quote': '[User testimonial]', 'author': 'Verified User'},
            'animation': 'fade_slide_up'
        },
        {
            'id': 7, 'name': 'cta', 'duration': 7,
            'type': 'call_to_action',
            'content': {
                'headline': 'Download $app_name Today',
                'subtitle': 'Available on the App Store',
                'badge': 'app_store_black'
            },
            'animation': 'bounce_in_with_particles'
        }
    ],
    'audio': {
        'background_track': 'sleek_corporate_tech',
        'sound_effects': [
            {'trigger': 'sequence_transition', 'sound': 'whoosh'},
            {'trigger': 'feature_tap', 'sound': 'soft_click'},
            {'trigger': 'stats_count', 'sound': 'tick'},
            {'trigger': 'cta_appear', 'sound': 'success_chime'}
        ]
    },
    'render_settings': {
        'codec': 'h264',
        'quality': 'high',
        'output': 'promo/videos/launch_video.mp4'
    }
}

output_path = os.path.join('$project_dir', 'promo', 'videos', 'remotion_spec.json')
with open(output_path, 'w') as f:
    json.dump(spec, f, indent=2)

print(f'Remotion spec saved to {output_path}')
print(f'7 sequences, {spec[\"duration_seconds\"]}s total')
" 2>/dev/null
}

# Generate complete video ad package for a project
# Usage: generate_video_ads "project_dir" "app_name" "category" "benefit" "audience" "color" "tagline"
generate_video_ads() {
    local project_dir="$1"
    local app_name="$2"
    local category="$3"
    local benefit="$4"
    local audience="$5"
    local color="$6"
    local tagline="$7"

    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Video Ads Generator — $app_name"
    echo "═══════════════════════════════════════════"
    echo ""

    generate_seedance_prompt "$project_dir" "$app_name" "$category"
    echo ""
    generate_ugc_scripts "$project_dir" "$app_name" "$benefit" "$audience"
    echo ""
    generate_remotion_spec "$project_dir" "$app_name" "$color" "$tagline"

    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Video Ad Package Complete"
    echo "  Output: $project_dir/promo/videos/"
    echo "═══════════════════════════════════════════"
}

echo "Video Ads Generator loaded. Available:"
echo "  generate_seedance_prompt <project_dir> <app_name> <category>"
echo "  generate_ugc_scripts <project_dir> <app_name> <benefit> <audience>"
echo "  generate_remotion_spec <project_dir> <app_name> <color> <tagline>"
echo "  generate_video_ads <project_dir> <app_name> <category> <benefit> <audience> <color> <tagline>"
