---
name: gym
description: Find an exercise in src/exercises.json and auto-populate its description, instructions, muscle groups, and YouTube Shorts video URL in all three languages (EN/RO/RU)
allowed-tools: Read, Edit, WebSearch, Bash, Skill, Agent
---

The user provides an exercise name. Find it in `src/exercises.json`, populate all fields, and save — no intermediate
output to the user.

## Steps

### 1. Read the file

Read `src/exercises.json` to find the exercise that matches the argument (case-insensitive name match).

### 2. Search for a YouTube Shorts video

If the exercise already has a non-empty `video` field, skip this step and keep the existing URL.

Otherwise, spawn an Agent to find the video URL:

> Search YouTube for a Shorts video of the exercise "<exercise name>". Use WebSearch with query
> `"<exercise name>" youtube shorts` restricted to youtube.com. Return only the first YouTube Shorts URL found
> (format: `https://www.youtube.com/shorts/...`). If no Shorts URL exists, return the first regular YouTube watch URL
> instead. Return just the URL, nothing else.

Use the URL returned by the agent.

### 3. Generate content

Invoke the `trainer` skill with the following prompt (substitute `<exercise name>` with the actual name):

> For the exercise **"<exercise name>"**, provide the following in a structured format:
>
> 1. **primary_muscles** and **secondary_muscles** — use ONLY muscles from this list:
     >    neck, traps, shoulders, chest, serratus anterior, biceps, brachialis, triceps, forearms, lats, abs, obliques, lower back, middle back, abductors, adductors, glutes, quads, hamstrings, calves, soleus
>
> 2. **English description** — 1–2 sentences describing the exercise purpose and benefit.
>
> 3. **English instructions** — exactly 4 steps as a numbered list.
>
> 4. **Romanian translations** — name, description, and all 4 instruction steps.
>
> 5. **Russian translations** — name, description, and all 4 instruction steps.
>
> Return only the structured data, no additional commentary.

Use the trainer's response internally — do NOT print it to the user.

### 4. Fix equipment

Review the exercise's current `equipment` array. Replace any values that are not in the valid enum with the closest
valid value. Valid values are:
`none`, `ez curl bar`, `barbell`, `dumbbell`, `gym mat`, `exercise ball`, `medicine ball`, `pull-up bar`, `bench`,
`incline bench`, `kettlebell`, `machine`, `cable`, `bands`, `foam roll`, `cardio machine`, `other`

Mapping guidance:

- Bodyweight / no equipment → `[]` (empty array, omit `none`)
- Any non-listed string (e.g. `"body only"`, `"cables"`) → map to the closest valid value
- If the exercise clearly needs equipment that isn't listed, use `"other"`

### 5. Edit the file

Use the Edit tool to update the matched exercise entry in `src/exercises.json` with:

- `description` (English)
- `instructions` (English, 4-item array)
- `primary_muscles` (array, from allowed list)
- `secondary_muscles` (array, from allowed list — always include the field; use `[]` if none)
- `equipment` (corrected array using only valid enum values)
- `enabled`: set to `true`
- `video` (YouTube URL)
- `translations.ro.name`, `translations.ro.description`, `translations.ro.instructions`
- `translations.ru.name`, `translations.ru.description`, `translations.ru.instructions`

Do NOT change `id`, `name`, `images`, or `category`.

### 6. Validate

Run the validation script to confirm the updated entry is correct:

```
bun scripts/validate-exercises.ts "<exercise name>"
```

If the script exits with a non-zero code, read the error output, fix the issues in `src/exercises.json`, and re-run
until it passes.

### 7. Confirm

After validation passes, output a single short confirmation line — nothing else:
`✓ Updated "<exercise name>" in exercises.json (video: <url>)`
