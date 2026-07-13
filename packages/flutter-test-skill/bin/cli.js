#!/usr/bin/env node

import { readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = join(__dirname, '..', 'skill');
const TEMPLATE_DIR = join(__dirname, '..', 'templates');

const commands = {
  install: 'Install the SKILL.md and templates into your project',
  init: 'Set up integration test directory structure (use --patrol for Patrol)',
  review: 'Print the test ID review checklist',
  templates: 'List available code templates',
  help: 'Show this help message',
};

function main() {
  const args = process.argv.slice(2);
  const cmd = args[0] || 'help';

  switch (cmd) {
    case 'install':
      return install(args.slice(1));
    case 'init':
      return init(args.slice(1));
    case 'review':
      return review();
    case 'templates':
      return listTemplates();
    case 'help':
    case '--help':
    case '-h':
      return help();
    default:
      console.error(`Unknown command: ${cmd}\n`);
      help();
      process.exit(1);
  }
}

function install(args) {
  const target = args[0] || process.cwd();
  const targetSkillsDir = join(target, '.skills');
  const targetSkillFile = join(targetSkillsDir, 'SKILL.md');

  console.log('Installing Flutter Test Interaction Skill...\n');

  if (!existsSync(targetSkillsDir)) {
    mkdirSync(targetSkillsDir, { recursive: true });
    console.log(`Created ${targetSkillsDir}`);
  }

  const skillSrc = join(SKILL_DIR, 'SKILL.md');
  if (existsSync(skillSrc)) {
    copyFileSync(skillSrc, targetSkillFile);
    console.log(`Installed SKILL.md -> ${targetSkillFile}`);
  } else {
    console.error('Error: SKILL.md not found in package');
    process.exit(1);
  }

  const targetTemplatesDir = join(targetSkillsDir, 'templates');
  if (!existsSync(targetTemplatesDir)) {
    mkdirSync(targetTemplatesDir, { recursive: true });
  }
  if (existsSync(TEMPLATE_DIR)) {
    for (const entry of readdirSync(TEMPLATE_DIR, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        const subDir = join(targetTemplatesDir, entry.name);
        if (!existsSync(subDir)) mkdirSync(subDir, { recursive: true });
        for (const file of readdirSync(join(TEMPLATE_DIR, entry.name))) {
          copyFileSync(join(TEMPLATE_DIR, entry.name, file), join(subDir, file));
          console.log(`Installed template: ${entry.name}/${file}`);
        }
      } else {
        copyFileSync(join(TEMPLATE_DIR, entry.name), join(targetTemplatesDir, entry.name));
        console.log(`Installed template: ${entry.name}`);
      }
    }
  }

  const agentsFile = join(target, 'AGENTS.md');
  const skillRef = `\n## Flutter Test Interaction Skill\nThe skill is installed at \`.skills/SKILL.md\`. When working on Flutter test coverage, read that file for instructions on adding test IDs and generating integration tests.\n`;

  if (existsSync(agentsFile)) {
    const content = readFileSync(agentsFile, 'utf8');
    if (!content.includes('Flutter Test Interaction Skill')) {
      writeFileSync(agentsFile, content + skillRef);
      console.log(`Updated ${agentsFile}`);
    }
  } else {
    writeFileSync(agentsFile, `# Agent Instructions\n${skillRef}`);
    console.log(`Created ${agentsFile}`);
  }

  console.log('\nInstallation complete!');
  console.log('\nNext steps:');
  console.log('  1. Add flutter_interaction_recorder to your pubspec.yaml');
  console.log('  2. Wrap your app with RecorderOverlay');
  console.log('  3. Add test IDs to all interactive widgets');
  console.log('  4. Run "npx @flutter-test-interaction/skill init" to set up test directories');
  console.log('  5. Ask your AI to read .skills/SKILL.md and review your app');
  console.log('  Tip: Use --patrol flag with init for Patrol test templates');
}

function init(args) {
  const usePatrol = args.includes('--patrol');
  const targetArg = args.find(a => !a.startsWith('--'));
  const target = targetArg || process.cwd();
  const testDir = join(target, 'integration_test');
  const sharedDir = join(testDir, 'shared');

  const framework = usePatrol ? 'Patrol' : 'Flutter';
  console.log(`Setting up ${framework} integration test directory structure...\n`);

  for (const dir of [testDir, sharedDir]) {
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
      console.log(`Created ${dir}`);
    } else {
      console.log(`Exists  ${dir}`);
    }
  }

  if (usePatrol) {
    const patrolTemplateDir = join(TEMPLATE_DIR, 'patrol');
    const templates = {
      'shared/shared_flows.dart': join(patrolTemplateDir, 'shared_flows_template.dart'),
      'shared/test_accounts.dart': join(patrolTemplateDir, 'test_accounts_template.dart'),
      'shared/test_helpers.dart': join(patrolTemplateDir, 'test_helpers_template.dart'),
    };

    for (const [dest, src] of Object.entries(templates)) {
      const destPath = join(testDir, dest);
      if (existsSync(src)) {
        copyFileSync(src, destPath);
        console.log(`Created ${destPath}`);
      } else if (!existsSync(destPath)) {
        writeFileSync(destPath, '// TODO: Add shared test flows here\n');
        console.log(`Created ${destPath} (stub)`);
      }
    }

    console.log('\nPatrol integration test directory ready!');
    console.log('Run tests with: patrol test --target integration_test/');
  } else {
    const templates = {
      'shared/shared_flows.dart': join(TEMPLATE_DIR, 'shared_flows_template.dart'),
      'shared/test_accounts.dart': join(TEMPLATE_DIR, 'test_accounts_template.dart'),
      'shared/test_helpers.dart': join(TEMPLATE_DIR, 'test_helpers_template.dart'),
    };

    for (const [dest, src] of Object.entries(templates)) {
      const destPath = join(testDir, dest);
      if (existsSync(src)) {
        copyFileSync(src, destPath);
        console.log(`Created ${destPath}`);
      } else if (!existsSync(destPath)) {
        writeFileSync(destPath, '// TODO: Add shared test flows here\n');
        console.log(`Created ${destPath} (stub)`);
      }
    }

    console.log('\nIntegration test directory ready!');
    console.log('Run tests with: flutter test integration_test/');
  }
}

function review() {
  const skillPath = join(SKILL_DIR, 'SKILL.md');
  if (existsSync(skillPath)) {
    const content = readFileSync(skillPath, 'utf8');
    const checklistMatch = content.match(/## Checklist for AI Review\n\n([\s\S]*?)(?=\n## )/);
    if (checklistMatch) {
      console.log('Test ID Review Checklist');
      console.log('========================\n');
      console.log(checklistMatch[1].trim());
      console.log('');
    } else {
      console.log(content);
    }
  } else {
    console.log('SKILL.md not found.');
  }
}

function listTemplates() {
  console.log('Available templates:\n');
  if (existsSync(TEMPLATE_DIR)) {
    for (const entry of readdirSync(TEMPLATE_DIR, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        console.log(`  ${entry.name}/`);
        for (const file of readdirSync(join(TEMPLATE_DIR, entry.name))) {
          console.log(`    ${file}`);
        }
      } else {
        console.log(`  ${entry.name}`);
      }
    }
  } else {
    console.log('  No templates found');
  }
}

function help() {
  console.log('Flutter Test Interaction Skill');
  console.log('');
  console.log('Usage: npx @flutter-test-interaction/skill <command> [options]');
  console.log('');
  console.log('Commands:');
  for (const [cmd, desc] of Object.entries(commands)) {
    console.log(`  ${cmd.padEnd(12)} ${desc}`);
  }
  console.log('');
  console.log('Options:');
  console.log('  --patrol     Use Patrol templates instead of standard Flutter (with init)');
  console.log('');
  console.log('Examples:');
  console.log('  npx @flutter-test-interaction/skill install');
  console.log('  npx @flutter-test-interaction/skill init');
  console.log('  npx @flutter-test-interaction/skill init --patrol');
  console.log('  npx @flutter-test-interaction/skill review');
}

main();
