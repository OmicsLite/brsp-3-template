# My BRSP Project

**Bioinformatics Research Starter Program · OmicsLite**

This repository is your workspace for BRSP. Everything runs in **GitHub Codespaces**: a Linux computer in the cloud that opens in your browser, with the bioinformatics tools already installed. You don't need to install anything on your own computer.

## Start your codespace

1. On this repository's page, click the green **Code** button.
2. Open the **Codespaces** tab and click **Create codespace on main**.
3. Wait while it sets up. **The first time takes about 3–6 minutes** because it installs the tools. You'll see a setup log; let it finish.
4. When VS Code appears in your browser, open a terminal: menu **☰ → Terminal → New Terminal**.
5. Check the tools work by typing:

   ```bash
   prokka --version
   datasets --version
   ```

   You should see `prokka 1.15.6` and `datasets version: 18.x.x`.

Next time, go to **Code → Codespaces** and click your existing codespace. It reopens with your tools and files still there.

## Weekly work

| Week | Guide |
|---|---|
| 2 · Genome annotation | [`week2/week2_annotation.sh`](week2/week2_annotation.sh) |
| 3 · Phylogenetics | *coming in Week 3* |
| 4–5 · Your project | *coming in Week 4* |

**How to follow a guide:** open it in the editor, then copy one block at a time into the terminal. Shortcut: select the lines and press **Ctrl+Shift+P → "Terminal: Run Selected Text in Active Terminal"**.

## Saving your work

Your files stay in your codespace, but your **portfolio is this GitHub repository**. Save to it at the end of each session:

```bash
git add .
git commit -m "Week 2: annotate E. coli K-12"
git push
```

Large files (downloaded genomes, some Prokka outputs) are skipped automatically by the `.gitignore` file.

## Use your free hours wisely

GitHub gives personal accounts a monthly free allowance of Codespaces hours, which is plenty for BRSP if you:

- **Stop your codespace when you finish** a session: **Code → Codespaces → ⋯ → Stop codespace**. (It also stops by itself after 30 minutes without activity.)
- **Keep just one codespace** for BRSP. Delete any extras from [github.com/codespaces](https://github.com/codespaces).

## Getting help

| Problem | Fix |
|---|---|
| `command not found: prokka` | Open a **new** terminal. Still missing? Check the setup log: `tail -n 20 ~/brsp-setup.log` |
| Setup failed while creating the codespace | Ask your TA, and include the last 20 lines of `~/brsp-setup.log` |
| Codespace won't start, or says you're out of hours | Delete old codespaces at [github.com/codespaces](https://github.com/codespaces), then ask your TA |

Post anything else in the WhatsApp group with: which step, the exact error (copy and paste), and what you already tried.
