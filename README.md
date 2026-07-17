# Analitik Tafakkur

Uzbek-first analytical task platform for grades 5-9.

Open `index.html` in a browser. For real registration, task storage, grading, and public statistics, connect Supabase:

1. Create a free Supabase project.
2. Run `database.sql` in Supabase SQL Editor. You can rerun it later; it upserts the task bank, demo stats, and views.
3. In `database.sql`, change the default professor invite code `ustoz-2026` if you want a private teacher code.
4. Copy your Supabase Project URL and anon/public key into `config.js`.
   ```js
   window.AT_SUPABASE = {
     url: "https://YOUR-PROJECT.supabase.co",
     anonKey: "YOUR-SUPABASE-ANON-OR-PUBLISHABLE-KEY"
   };
   ```
5. For easy testing, disable email confirmation in Supabase Auth settings, or keep it enabled for production.
6. Deploy the folder to GitHub Pages or Netlify.

Never put a Supabase `service_role` key in this frontend app. The anon/public key is expected to be visible; security is handled by Row Level Security in `database.sql`.

## Task Bank And Ratings

`task-bank.js` contains the pasted 5th, 6th, 7th, 8th, and 9th grade tasks: 2 tasks for every method in each grade, 80 tasks total.

The public leaderboard is anonymous. It shows random-looking IDs instead of student names or schools. Real graded submissions are still added automatically to the same global statistics after a professor grades them.

`database.sql` also seeds 402 anonymous demo rating records across grades 5-9. Their average score is exactly 65, so the public statistics look active before real students begin using the platform.

## Public Deployment

Easiest free option:

1. Create a public GitHub repository, for example `analitik-tafakkur`.
2. Upload `index.html`, `styles.css`, `app.js`, `config.js`, and `database.sql`.
3. In GitHub: Settings -> Pages -> Build and deployment -> Deploy from a branch.
4. Choose `main` and `/root`, then save.
5. GitHub will give you a public URL like `https://USERNAME.github.io/analitik-tafakkur/`.

Alternative quick test:

1. Sign in to Netlify.
2. Drag this project folder into Netlify's deploy area.
3. Netlify gives a public test URL immediately.

## First Test

1. Register one professor using the invite code from `database.sql`.
2. Register one student in grade 5-9.
3. Submit a student answer.
4. Open the professor side, grade the answer, and check that the public leaderboard updates.
