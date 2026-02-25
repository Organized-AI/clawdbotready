# Creative Formats — Asset Specs and Upload Workflow

## Table of Contents
- [Image Specs by Placement](#image-specs-by-placement)
- [Video Specs](#video-specs)
- [Copy Framework](#copy-framework)
- [Image Upload Workflow](#image-upload-workflow)
- [Video Upload Workflow](#video-upload-workflow)
- [Thumbnail Options](#thumbnail-options)
- [Copy Testing Matrix](#copy-testing-matrix)
- [Preview and QA](#preview-and-qa)

## Image Specs by Placement

| Placement | Size | Ratio | Format | Max Size |
|-----------|------|-------|--------|----------|
| Feed (FB + IG) | 1080x1080 | 1:1 | JPG/PNG | 30MB |
| Stories / Reels | 1080x1920 | 9:16 | JPG/PNG | 30MB |
| Right Column | 1200x628 | 1.91:1 | JPG/PNG | 30MB |
| Marketplace | 1080x1080 | 1:1 | JPG/PNG | 30MB |
| Search Results | 1080x1080 | 1:1 | JPG/PNG | 30MB |
| Carousel Card | 1080x1080 | 1:1 | JPG/PNG | 30MB |
| Collection Cover | 1080x1080 | 1:1 | JPG/PNG | 30MB |

Rules:
- Max 20% text on image (soft rule, affects delivery not rejection)
- No watermarks or third-party logos in primary area
- PNG for graphics with text, JPG for photos
- Text must be readable at mobile scale

## Video Specs

| Spec | Requirement |
|------|------------|
| Format | MP4 (preferred) or MOV |
| Codec | H.264 video, AAC audio |
| Resolution | 1080x1080 (1:1) or 1080x1920 (9:16) minimum |
| Frame rate | 30fps recommended |
| Duration | 1s to 241min (15s recommended for Stories/Reels) |
| Max file size | 4GB |
| Aspect ratios | 1:1 (feed), 9:16 (stories/reels), 16:9 (in-stream), 4:5 (feed alt) |

## Copy Framework

### Character Limits

| Element | Full Display | Hard Max |
|---------|-------------|----------|
| Primary text | 125 chars | 2,200 chars |
| Headline | 40 chars | 255 chars |
| Description | 30 chars | 255 chars (not shown in all placements) |

### Primary Text (above creative)
- Front-load value proposition in first line
- Use line breaks for mobile readability
- Keep under 125 chars for full visibility without "See More"

### Headline (below creative)
- State the offer or outcome
- 40 chars or fewer for full display

### Description
- Supporting detail or social proof
- 30 chars or fewer

## Image Upload Workflow

```bash
# Step 1: Upload
curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/adimages" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -F "filename=@/path/to/creative_v1.jpg"

# Step 2: Extract and store hash
IMAGE_HASH=$(echo "$RESPONSE" | jq -r '.images | to_entries[0].value.hash')
echo "Stored image_hash: ${IMAGE_HASH}"
```

For base64 upload:
```bash
curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/adimages" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"bytes\": \"$(base64 -w0 /path/to/image.jpg)\"}"
```

## Video Upload Workflow

```bash
# Step 1: Upload (under 1GB)
RESPONSE=$(curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/advideos" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -F "source=@/path/to/video.mp4" \
  -F "title=Product Demo V1")

VIDEO_ID=$(echo "$RESPONSE" | jq -r '.id')

# Step 2: Poll until ready (every 10 seconds, timeout 10 minutes)
for i in $(seq 1 60); do
  STATUS=$(curl -s "https://graph.facebook.com/v21.0/${VIDEO_ID}?fields=status&access_token=${META_ACCESS_TOKEN}" | jq -r '.status.video_status')
  echo "Video status: ${STATUS} (attempt ${i}/60)"
  if [ "$STATUS" = "ready" ]; then
    echo "Video ready!"
    break
  fi
  sleep 10
done
```

## Thumbnail Options

```bash
# Option A: Auto-generated (default — no action needed)

# Option B: Custom thumbnail
# Upload image first, get the URL from response
THUMB_RESPONSE=$(curl -X POST "https://graph.facebook.com/v21.0/act_${META_AD_ACCOUNT_ID}/adimages" \
  -H "Authorization: Bearer ${META_ACCESS_TOKEN}" \
  -F "filename=@/path/to/thumbnail.jpg")

THUMB_URL=$(echo "$THUMB_RESPONSE" | jq -r '.images | to_entries[0].value.url')

# Use THUMB_URL as image_url in video_data creative spec
```

## Copy Testing Matrix

Build creatives with variable components for A/B testing:

| Component | Variant A | Variant B | Variant C |
|-----------|-----------|-----------|-----------|
| Hook (first line) | Problem statement | Bold claim | Question |
| Body | Feature-benefit | Social proof | Urgency |
| Headline | Offer-focused | Outcome-focused | CTA-focused |
| CTA Button | SHOP_NOW | LEARN_MORE | GET_OFFER |

For DCO (Dynamic Creative), provide multiple variants in `asset_feed_spec` and Meta tests combinations automatically. The ad set must have `use_dynamic_creative: true`.

## Preview and QA

After creating an ad, generate previews:

```bash
# Get preview HTML
curl -s "https://graph.facebook.com/v21.0/${AD_ID}/previews?ad_format=DESKTOP_FEED_STANDARD&access_token=${META_ACCESS_TOKEN}" | jq '.data[0].body'

# Get shareable preview link
curl -s "https://graph.facebook.com/v21.0/${AD_ID}?fields=preview_shareable_link&access_token=${META_ACCESS_TOKEN}" | jq -r '.preview_shareable_link'
```

Available preview formats:
- DESKTOP_FEED_STANDARD
- MOBILE_FEED_STANDARD
- MOBILE_FEED_BASIC
- RIGHT_COLUMN_STANDARD
- INSTAGRAM_STANDARD
- INSTAGRAM_STORY
- MARKETPLACE_MOBILE
- AUDIENCE_NETWORK_OUTSTREAM_VIDEO
