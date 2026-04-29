# Workflow: Generate UGC-Style Product Images

**Trigger:** "generate UGC images for [client/product]" or client content request for product lifestyle imagery
**Also triggered by:** Content calendar requiring product visuals, ad creative refresh cycle

---

## Pre-flight

Before starting, read:
- `context/rules.md` — confirm before publishing or sending any assets externally
- `clients/[client-name]/profile.md` — brand guidelines, tone, target audience
- `clients/[client-name]/performance.md` — what visual styles have performed best historically
- `blueprint/content-farming/pillars.md` — ensure imagery aligns with content pillars
- The client's **ingredient/product reference images** — these are the ground truth for every prompt

---

## Steps

### 1. Audit the Product & Ingredient Reference Images

Pull up every available product photo and ingredient shot the client has provided. For each image, document:

| Detail | What to capture |
|--------|----------------|
| **Product name** | Exact product name, variant, flavour |
| **Packaging** | Container type (tub, pouch, bottle, sachet), colour scheme, label design, lid/cap style |
| **Label text** | Brand name, product name, key claims on the label (e.g. "1000mg Vitamin C", "Grass-Fed Whey") |
| **Ingredient visuals** | Every visible ingredient — exact form (whole blueberries, sliced almonds, raw honey drizzle, matcha powder, cacao nibs, chia seeds, etc.) |
| **Colours** | Dominant colours of packaging, powder/liquid inside, ingredient tones |
| **Textures** | Powder grain, liquid viscosity, fruit skin, nut surface, leaf veining |
| **Scale** | Approximate product size relative to a hand, kitchen counter, or table |

**Critical rule:** Do not invent ingredients or features not visible in the reference images. The prompt must only describe what is actually in/on the product.

---

### 2. Define the UGC Scene Context

For each image batch, decide the scene setup. UGC-style means it should look like a real customer took the photo — not a studio, not a brand shoot.

Pick from these scene archetypes (or combine):

| Scene Type | Description | Best for |
|------------|-------------|----------|
| **Kitchen counter** | Product on a granite/marble/wood counter with morning light, alongside real breakfast items | Supplements, protein, superfoods |
| **Post-workout** | Product next to a gym bag, shaker, towel, AirPods, sweaty water bottle | Pre/post-workout, protein, BCAAs |
| **Morning routine** | Bathroom shelf or bedside table, golden hour light, coffee mug in background | Vitamins, daily supplements, wellness |
| **Flat lay** | Top-down shot on a textured surface, product surrounded by its raw ingredients | Any product with photogenic ingredients |
| **In-hand / selfie style** | Hand holding the product, slightly off-centre, casual grip, blurred background | Trust-building, social proof style |
| **Smoothie/recipe** | Product open next to a blender, chopping board with fresh fruit, half-made smoothie | Powders, superfoods, collagen |
| **Desk/work** | Product on a desk next to a laptop, notebook, coffee — "productive day" energy | Nootropics, focus supps, energy |
| **Outdoor/lifestyle** | Product in a tote bag, on a park bench, picnic blanket, hiking setup | Portable products, bars, sachets |

---

### 3. Build the JSON Prompt

Every prompt must be structured as a JSON object with all elements explicitly defined. Do not skip any field. This ensures consistency, repeatability, and easy editing across batches.

#### JSON Prompt Schema

```json
{
  "subject": {
    "product_name": "[Exact product name from reference — brand, variant, flavour]",
    "container": "[Tub / pouch / bottle / sachet / jar / box]",
    "packaging_colour": "[Exact colours — e.g. matte black with gold accents]",
    "label_text": "[Key text visible on the label — brand name, claims, weight, flavour]",
    "label_design": "[Layout description — colours, fonts, logo placement, accent details]",
    "lid_cap": "[Colour, material, state — on / off / askew / placed beside product]",
    "product_visible": "[If open: powder colour, texture, scoop visibility, fill level]",
    "product_scale": "[Size reference — e.g. standard supplement tub, palm-sized sachet]"
  },
  "setting": {
    "location": "[Kitchen counter / gym bag / desk / outdoor / bathroom shelf / picnic blanket]",
    "surface": "[White marble / butcher block oak / dark granite / raw concrete / linen tablecloth]",
    "time_of_day": "[Early morning golden hour / midday bright / late afternoon warm / overcast soft]",
    "light_source": "[Window to the left / overhead skylight / natural backlight / open shade]",
    "light_quality": "[Warm golden / cool crisp / soft diffused / dappled through blinds]",
    "background_objects": "[2-3 contextual items — e.g. ceramic coffee mug, folded newspaper, succulent plant]",
    "environment_feel": "[Lived-in, slightly cluttered / minimal and clean / cosy and warm / active and energetic]"
  },
  "ingredients": [
    {
      "name": "[Ingredient name — from reference image ONLY]",
      "form": "[Whole / sliced / crushed / powdered / drizzled / halved / shaved]",
      "quantity": "[A few / a small pile / scattered / a single / a handful / a light dusting]",
      "colour": "[Specific — deep indigo-purple / warm amber-gold / vivid jade-green / charcoal-grey]",
      "texture": "[Glossy / matte / rough / glistening / frosted / silky / fibrous / papery]",
      "arrangement": "[Scattered casually on surface / in a small ceramic bowl / on a wooden spoon / mid-pour / rolling off edge]",
      "interaction": "[Powder dusted on counter / juice staining the surface / honey dripping off a dipper / seeds spilling from a torn sachet]"
    }
  ],
  "camera": {
    "device": "[iPhone 15 Pro / Samsung Galaxy S24 Ultra / Google Pixel 8 Pro]",
    "angle": "[Slightly above 30° / eye-level / top-down flat lay / low angle looking up / candid off-centre]",
    "distance": "[Close-up tight crop / medium shot showing counter context / wide showing full scene]",
    "depth_of_field": "[Shallow — background softly blurred / moderate — background objects recognisable but soft / deep — everything sharp]",
    "composition": "[Off-centre, rule of thirds / slightly tilted casual / centred but imperfect / product at edge of frame]"
  },
  "human_element": {
    "included": true,
    "body_part": "[Hand / forearm and hand / fingers only / no human element]",
    "action": "[Reaching for product / holding scoop / mid-pour into blender / gripping tub / unscrewing lid]",
    "skin_tone": "[Light / medium / dark / varied]",
    "details": "[Sleeve of an oversized grey hoodie / bare arm with a simple silver watch / pastel painted nails / gym glove on one hand]",
    "pose_feel": "[Casual mid-action / relaxed grip / intentional but not posed]"
  },
  "mood": {
    "overall_vibe": "[Warm and cosy / fresh and energetic / calm and minimal / vibrant and punchy]",
    "colour_grading": "[Warm golden tones / cool crisp daylight / neutral true-to-life / slightly desaturated matte]",
    "shadows": "[Soft natural shadows / long morning shadows / minimal flat light / dappled light-and-shadow pattern]",
    "imperfection": "[A small crumb on the counter / a drip of smoothie on the rim / slightly crooked label / fingerprint on the tub / a berry that rolled away]",
    "authenticity_cue": "[Looks like it was posted on Instagram Stories by a real customer, not a brand account]"
  },
  "negative_prompt": "[studio lighting, professional photography, stock photo, 3D render, illustration, cartoon, anime, CGI, airbrushed, perfect symmetry, overly saturated, plastic-looking, floating objects, extra fingers, deformed hands, watermark, text overlay, blurry product, white void background]",
  "output": {
    "aspect_ratio": "[4:5 portrait / 1:1 square / 9:16 story / 16:9 landscape]",
    "target_platform": "[Instagram feed / Instagram Stories / TikTok / Facebook ad / Website hero]",
    "target_model": "[Midjourney v6.1 / DALL-E 3 / Flux 1.1 Pro / Ideogram 2.0 / Stable Diffusion XL]"
  }
}
```

---

### 4. Filled Example — Complete JSON Prompt

This is what a production-ready prompt looks like. Every field references real product details from the client's ingredient/product images.

```json
{
  "subject": {
    "product_name": "NutraForce Whey Isolate — Chocolate Brownie",
    "container": "Tub — standard 900g supplement tub with screw lid",
    "packaging_colour": "Matte black body, dark charcoal grey label wrap",
    "label_text": "NutraForce logo top-centre, 'WHEY ISOLATE' in bold white, 'Chocolate Brownie' in gold script, '100% Grass-Fed — 30g Protein Per Serving' in smaller white text, '900g / 30 Servings' bottom-right",
    "label_design": "Dark grey base with a thin gold pinstripe border, brand logo embossed, clean modern sans-serif font, ingredient splash graphic on the lower third showing cacao and chocolate chunks",
    "lid_cap": "Gold metallic screw-top lid, removed and placed to the right of the tub, resting upside-down",
    "product_visible": "Fine chocolate-brown powder visible inside, a black plastic scoop half-buried with a rounded scoop of powder, powder level at about 70% full",
    "product_scale": "Standard supplement tub, roughly 18cm tall — slightly larger than a coffee mug"
  },
  "setting": {
    "location": "Kitchen counter in a modern apartment",
    "surface": "White Carrara marble countertop with subtle grey veining",
    "time_of_day": "Early morning, approximately 7:30am",
    "light_source": "Large window to the left, natural daylight streaming in at a low angle",
    "light_quality": "Warm golden hour light with soft shadows stretching to the right",
    "background_objects": "A half-drunk flat white in a speckled ceramic mug, a folded copy of a broadsheet newspaper, the edge of a wooden cutting board with a sliced banana on it",
    "environment_feel": "Lived-in and slightly cluttered — a real kitchen in the middle of breakfast prep, not staged"
  },
  "ingredients": [
    {
      "name": "Raw cacao pods",
      "form": "Whole — one cracked open showing the pale beans inside",
      "quantity": "Three pods total, one split",
      "colour": "Deep reddish-brown exterior, pale cream beans inside",
      "texture": "Rough, ridged outer shell with a woody feel",
      "arrangement": "Grouped to the left of the tub, one pod cracked open facing the camera",
      "interaction": "A few loose cacao beans have spilled onto the marble surface"
    },
    {
      "name": "Dark cacao nibs",
      "form": "Crushed irregular chunks",
      "quantity": "A small scattered pile, roughly a tablespoon",
      "colour": "Dark chocolate brown, almost black",
      "texture": "Rough, bark-like, matte surface",
      "arrangement": "Scattered loosely in front of the tub on the marble",
      "interaction": "A light dusting of cocoa powder surrounds the nib pile on the white marble"
    },
    {
      "name": "Dark chocolate squares",
      "form": "Two squares snapped from a bar with a clean break edge",
      "quantity": "Two pieces",
      "colour": "Rich dark brown with a slight sheen",
      "texture": "Smooth top surface, rough snap-edge showing the interior grain",
      "arrangement": "Leaning against the base of the tub on the right side",
      "interaction": "A tiny chocolate crumb has fallen onto the marble near the squares"
    },
    {
      "name": "Whole hazelnuts",
      "form": "Whole, raw, skin-on",
      "quantity": "A small handful — roughly 8-10 nuts",
      "colour": "Warm tan-brown shells",
      "texture": "Smooth, hard shell with a slight natural sheen",
      "arrangement": "In a small white ceramic pinch bowl behind the tub, slightly out of focus",
      "interaction": "Two hazelnuts have rolled out of the bowl onto the counter"
    }
  ],
  "camera": {
    "device": "Shot on iPhone 15 Pro",
    "angle": "Slightly above, approximately 30 degrees — looking down at the counter",
    "distance": "Medium shot — full tub visible with 15cm of counter space on each side",
    "depth_of_field": "Shallow — the newspaper and mug in the background are softly blurred, the product and near ingredients are tack-sharp",
    "composition": "Product placed at the right third of the frame, ingredients filling the left and centre, slightly off-centre and imperfect — not a symmetrical layout"
  },
  "human_element": {
    "included": false,
    "body_part": "None",
    "action": "None",
    "skin_tone": "N/A",
    "details": "N/A",
    "pose_feel": "N/A"
  },
  "mood": {
    "overall_vibe": "Warm, cosy, indulgent morning ritual",
    "colour_grading": "Warm golden tones — slightly amber, like an unedited iPhone photo in morning light",
    "shadows": "Soft, long morning shadows stretching gently to the right from the window light",
    "imperfection": "A tiny smudge of cocoa powder on the marble near the lid, and the scoop handle is slightly crooked in the powder",
    "authenticity_cue": "This looks exactly like a fitness influencer snapped a quick photo of their morning protein setup before making a shake — posted to Instagram Stories with no editing"
  },
  "negative_prompt": "studio lighting, professional photography, stock photo, 3D render, illustration, cartoon, anime, CGI, airbrushed, perfect symmetry, overly saturated, plastic-looking, floating objects, extra fingers, deformed hands, watermark, text overlay, blurry product, white void background, commercial shoot, advertising, perfect composition",
  "output": {
    "aspect_ratio": "4:5 portrait",
    "target_platform": "Instagram feed",
    "target_model": "Midjourney v6.1"
  }
}
```

---

### 5. Generate Prompt Variations

For each product, produce **4 prompt variants** across different scenes:

| Variant | Scene | Angle | Human element |
|---------|-------|-------|---------------|
| A | Kitchen counter / flat lay | Slightly above, 30° angle | No hand |
| B | In-use (smoothie, shaker, recipe) | Eye-level, casual | Hand mid-action |
| C | Lifestyle context (desk, gym, outdoor) | Candid, off-centre | Partial body or hand |
| D | Close-up / detail shot | Macro-ish, tight crop on product + 1-2 ingredients | No hand |

Each variant must reference the **same product details and real ingredients** from the reference images — only the scene and angle change.

---

### 6. Quality Control Checklist

Before presenting any prompt, verify:

- [ ] **Product accuracy** — packaging, label text, colours, and container match the reference exactly
- [ ] **Ingredient accuracy** — only ingredients visible in the reference images are described
- [ ] **No hallucinated details** — nothing invented, no generic stock-photo filler
- [ ] **Realism anchors present** — camera model, natural light, imperfection detail included
- [ ] **UGC feel** — reads like a real person's photo, not a brand shoot or 3D render
- [ ] **Scene coherence** — all objects in the scene make sense together (no gym towel on a breakfast table)
- [ ] **Specificity** — every noun has an adjective, every ingredient has a form/texture/colour
- [ ] **No banned terms** — avoid "professional", "studio", "perfect", "flawless", "high-end", "commercial" — these push AI toward polished renders

---

### 7. Present for Review

Present all prompt variants to the user with:
- The reference image(s) used as the source
- Each prompt clearly labelled (Variant A, B, C, D)
- A note on which text-to-image model each is optimised for (Midjourney, DALL-E, Flux, Ideogram, etc.)

**Do not generate or publish images without explicit confirmation.**

---

### 8. Post-Generation Review

After images are generated, review each output against the reference images:

| Check | Pass/Fail |
|-------|-----------|
| Product packaging matches reference | |
| Label text is legible and accurate | |
| Ingredient types match (no phantom ingredients) | |
| Lighting feels natural / phone-camera quality | |
| No AI artifacts (extra fingers, warped text, melted edges) | |
| Overall UGC authenticity — would you believe a customer posted this? | |

Flag any failed checks. Re-prompt with corrections where needed.

---

### 9. Update Memory and Logs

- Log in `logs/tasks.md`: UGC Image Generation — [client] — [date] — [number of variants] — Completed
- Log in `logs/actions.md` if images were sent to the client or published
- Update `clients/[client-name]/performance.md` if engagement data comes back on the images
- Save successful prompt patterns to `memory/learnings.md` for future reuse

---

## Expected Output

A set of 4 highly detailed, reference-accurate text-to-image prompts per product that produce photorealistic UGC-style product imagery when run through any major AI image generator.

---

## Prompt Bank — Common Ingredients

Use these descriptions when the corresponding ingredient appears in a client's reference images. Adapt form/arrangement to the specific photo.

| Ingredient | Photorealistic Description |
|------------|---------------------------|
| Blueberries | Plump, deep indigo-purple blueberries with a light dusty bloom on the skin, a few slightly crushed showing dark juice |
| Strawberries | Ripe red strawberries with visible seed dimples, one sliced in half showing the pale interior gradient from white to red |
| Banana | A ripe banana with light brown freckles on the peel, one segment sliced into 1cm rounds showing creamy off-white flesh |
| Spinach | Fresh baby spinach leaves, deep emerald green, slightly curled at the edges, delicate veining visible |
| Matcha | Fine-ground vivid jade-green matcha powder, slightly clumped, dusted across the surface like pollen |
| Cacao/Cocoa | Dark chocolate-brown cacao powder, rich and matte, with a few raw cacao nibs (dark, irregular, bark-like texture) |
| Whey protein | Fine off-white to cream powder with a silky, flour-like texture, a scoop with a slightly rounded top |
| Honey | Thick, viscous amber-gold honey mid-drip from a wooden honey dipper, catching the light with a translucent glow |
| Oats | Rolled oats — flat, pale tan, papery texture, a small scatter of loose flakes on the surface |
| Almonds | Whole raw almonds, warm tan-brown skin with visible grain, a few halved showing the smooth cream interior |
| Chia seeds | Tiny dark charcoal-grey seeds, almost black, in a dense cluster — some with a slight sheen |
| Coconut | White coconut flakes or shavings, thin and curled, matte white, alongside a halved brown coconut shell |
| Turmeric | Vivid deep orange-yellow powder, staining everything it touches, with a small knob of raw turmeric root (brown skin, bright orange interior) |
| Ginger | Fresh ginger root, knobby, pale tan papery skin partially peeled to reveal the fibrous pale yellow flesh |
| Peanut butter | Thick, glossy tan-brown paste with a slightly rough surface and natural oil sheen, in a jar or on a spoon |
| Collagen | Ultra-fine white powder, almost translucent, lighter and finer than whey — dissolves-in-air texture |
| Acai | Deep purple-black acai in a bowl (frozen puree), topped with granola and fruit, or as freeze-dried powder |
| Ashwagandha | Fine khaki-brown powder with an earthy, slightly sandy texture, or dried root pieces (woody, pale brown) |
| Creatine | Pure white crystalline powder, slightly granular — looks like fine sugar, bright white |
| BCAAs | Fine white powder (unflavoured) or coloured powder (flavoured), similar grain to protein powder |

---

## Negative Prompt Bank

Include these terms as negative prompts (where the image model supports them) to avoid common AI image failures:

```
studio lighting, professional photography, stock photo, 3D render,
illustration, cartoon, anime, CGI, airbrushed skin, perfect symmetry,
overly saturated colours, plastic-looking, floating objects, extra
fingers, deformed hands, watermark, text overlay, blurry, out of
focus product, generic background, white void background
```

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| No ingredient reference images provided | Ask the client for ingredient photos or an ingredient list. Do not guess ingredients. |
| Product label text is unreadable in reference | Ask for a higher resolution image or the exact label copy. Do not approximate text. |
| Client wants a style not covered by the scene types | Extend the scene list — document the new archetype for reuse. |
| AI model produces persistent artifacts on a specific product | Switch models (e.g. Midjourney → Flux) or simplify the prompt and rebuild layer by layer. |
| Client wants the image to include people's faces | Flag that AI-generated faces carry legal and ethical risks. Recommend hands/arms only, or shot-from-behind angles. Use with explicit client sign-off only. |
| Required data is missing | Flag to user before proceeding. Do not guess or generate synthetic data. |
| External tool is inaccessible | Note the gap in output. Produce what you can from local files. |
