---
name: frontend-design
description: Guidance for distinctive, intentional visual design when building new UI or reshaping an existing one in the Quest Flutter codebase. Helps with aesthetic direction, typography, and making choices that align with the specific app style.
license: Complete terms in LICENSE.txt
---

# Frontend Design (Flutter)

Approach this as the design lead at a design studio known for giving every client a distinct visual identity that is not mistaken for anyone else's. This client has already rejected proposals that felt cliché or templated, and is paying for a distinctive point of view: make deliberate, opinionated choices about palette, typography, and layout that are specific to this brief, and take aesthetic risk if justified.

## Ground your designs in the subject matter

If the brief does not identify what the product or subject matter is, identify it yourself before designing, and confirm with the client. The subject's industry, subject matter, materials, and vernacular are where distinctive visual choices come from. Build with the brief's real content and subject matter throughout.

## Design principles

For Flutter designs, the hero is the first thing viewers will see. Open with the most characteristic thing in the subject's world, in the form that is most appropriate: a headline, an image, an animation, a live demo, an interactive moment, or other treatments. Be deliberate with your choice.

Typography carries the personality of the page. You don't need a different typeface for display or headline text and body content: use one family or two, and if two, make them clearly distinct. Define these via the app's `ThemeData` and `TextTheme` where possible.

Choose your typefaces deliberately, and set a clear type scale following the default guidance of The Elements of Typographic Style with intentional weights, widths, and spacing. When type is used as a headline or visual element, use the type treatment itself as an active part of the design.

Avoid these default typographic treatments:
- Accenting just a single word or phrase in a headline in a cliché way.
- Using all caps for labels indiscriminately.
- Adding unnecessary typographic labels above content.

Visual structure is information. Structural devices like outlines, borders, numbering, eyebrows, dividers, labels, etc., encode useful information about the content rather than decorate it. Many generic designs use numbered markers (01 / 02 / 03), but that's only appropriate if the content actually is a sequence.

Use non-user-triggered motion sparingly and deliberately, only to draw attention. Motion that answers a person's action (opening, expanding, confirming) is highly recommended. In Flutter, use fluid spring animations, tactile haptic feedback (`HapticFeedback`), and implicit animations (`AnimatedContainer`, `AnimatedOpacity`) to make the interface feel alive and responsive. 

Consider written content carefully. Copy can make a design feel as templated as the design itself. See the below section on writing for more guidance.

## Process: plan, review against the brief, build, critique

For calibration, generic generated app design right now clusters around some traits:
1. The standard Material boilerplate: default blue (`Colors.blue`), unstyled `AppBar`, and standard `FloatingActionButton` without customization.
2. Overuse of standard `Card` widgets with default elevation and border radius, making everything look like a generic SaaS dashboard.
3. Lack of cohesive spacing; slapping random `Padding` or `SizedBox` instead of using a unified layout grid or spacing tokens.

All traits are legitimate for some briefs, but they are defaults rather than choices. Where the brief pins down a visual direction, follow it exactly.

Work in two passes. First, brainstorm a short design plan based on the client's design brief:
- Color: Ensure you strictly adhere to the design system defined in `lib/core/theme/app_colors.dart`. Avoid hardcoding hex values (`Color(0xFF...)`) if a semantic token exists.
- Type: The typefaces and their roles, defined in the `TextTheme`.
- Layout: A layout concept, using one-sentence prose descriptions. Include alignment guidance.
- Micro-interactions: Define the tactile haptic feedback and fluid spring animations that will accompany interactive actions (as required by `AGENTS.md`).

Then review that plan against the brief before building. If any part of it reads like the generic default, revise it. Only after you've confirmed the relative uniqueness of your design plan should you start to write the Dart code.

When writing the Flutter code, be careful with widget tree depth. Use helper widgets and extensions for complex UI, but avoid premature abstraction. Prefer composing smaller widgets together over massive `build` methods.

## Restraint and self-critique

Spend your boldness in one place. Let one element be the memorable thing, keep everything around it quiet and disciplined, and cut any decoration that does not serve the brief. Build to a quality floor without announcing it: responsive on all device sizes, visually accessible, and harmonious color palettes. Critique your own work as you build.

## More on writing in design

Words appear in a design for one reason: to make it easier to understand and use. They are design content, not decoration. Bring the same intentionality and minimalism to copywriting that you would bring to spacing and color.

Write from the end user's perspective. Name things by what users will understand in simple language, not by how the system is built. 

Use active voice as default. A CTA says exactly what happens when it is used: "Save changes," not "Submit." An action keeps the same name through the whole flow.

Treat failure and emptiness as moments for direction, not mood. Explain what went wrong and how to fix it. An empty screen is an invitation to act.

Keep the tone conversational: plain verbs, sentence case, no filler, with tone matched to the brand and the audience.
