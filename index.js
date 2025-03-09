#!/usr/bin/env node
'use strict';

// Load Module Dependencies
import { Command } from 'commander';
import inquirer from 'inquirer';
import path from 'path';

// Load Generators
import nodeGenerator from './generators/node.js';

const program = new Command();
program
    .version('0.0.1')
    .description('Zac Austin Project Generator')
    .argument('[destination]', 'Project path (default: current directory)', '.')
    .action(async (destination) => {
        // Step 1: Resolve absolute project path
        const projectPath = path.resolve(destination);

        // Step 2: Determine project type before proceeding
        const { language } = await inquirer.prompt([{
            type: 'list',
            name: 'language',
            message: 'Select project type:',
            choices: ['NodeJS', 'C++']
        }]);

        // Step 3: Pass to the appropiate generator
        switch(language) {
            case 'NodeJS': return nodeGenerator(projectPath);
            default: return console.log(`${language} projects are not yet supported.`);
        }
    });

program.parse(process.argv);