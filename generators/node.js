'use strict';

// Load Module Dependencies
import inquirer from 'inquirer';
import path from 'path';
import fs from 'fs';

// Store Versions
// TODO: Move this map off to a different file.
const versions = new Map();
versions.set("nodemon", "^3.1.9");
versions.set("jest", "^29.7.0");
versions.set("debug", "^4.4.0");
versions.set("dotenv", "^16.4.7");
versions.set("express", "^4.21.2");
versions.set("module-alias", "^2.2.3");
versions.set("mysql2", "^3.13.0");
versions.set("sequelize", "^6.37.6");
versions.set("sequelize-cli", "^6.6.2");
versions.set("sqlite3", "^5.1.7");

export default async function (projectPath) {
    const {
        projectName,
        projectDebugIdentifer,
        projectVersion,
        projectType,
        projectPrivacy,
        projectDescription,
        projectAuthor,
        projectLicence,
        projectTemplate,
        projectFeatures
    } = await inquirer.prompt([
        {
            type: 'input',
            name: 'projectName',
            message: 'Project Name:',
            default: path.basename(projectPath)
        },
        {
            type: 'input',
            name: 'projectDebugIdentifer',
            message: 'Project Debug Identifier:',
            default: "app"
        },
        {
            type: 'input',
            name: 'projectVersion',
            message: 'Version:',
            default: '0.0.1',
            validate: (input) => /^\d+\.\d+\.\d+$/.test(input) ? true : 'Enter a valid version (e.g., 1.0.0)'
        },
        {
            type: 'list',
            name: 'projectType',
            message: 'Module Type:',
            choices: ['CommonJS', 'Module'],
            default: 'CommonJS'
        },
        {
            type: 'list',
            name: 'projectPrivacy',
            message: 'Project Visibility:',
            choices: ['Private', 'Public'],
            default: 'Private'
        },
        {
            type: 'input',
            name: 'projectDescription',
            message: 'Description:',
            default: ''
        },
        {
            type: 'input',
            name: 'projectAuthor',
            message: 'Author:',
            default: ''
        },
        {
            type: 'list',
            name: 'projectLicence',
            message: 'License:',
            choices: [
                'UNLICENCED', 'MIT', 'ISC', 'Apache-2.0', 'GPL-3.0', 'BSD-2-Clause', 'BSD-3-Clause', 'AGPL-3.0', 'Unlicense'
            ],
            default: 'UNLICENCED'
        },
        {
            type: 'list',
            name: 'projectTemplate',
            message: 'Template:',
            choices: [
                'Generic', 'Backend', 'Frontend', 'Full Stack', 'Generic', 'Commandline Tool'
            ],
            default: 'Generic',
        },
        {
            type: 'checkbox',
            name: 'projectFeatures',
            message: 'Select additional project features:',
            choices: [
                { name: 'Sequelize', value: 'sequelize' },
                { name: 'Jest', value: 'jest' },
            ],
            default: []
        }

        // TODO: VSCode Dev Container Configuration
        // TODO: Docker Configuration
    ]);

    // Determine Entry Point based on template selection
    const projectEntryPoint = "index.js";
    switch (projectTemplate) {
        case "Backend": projectEntryPoint = "./bin/www"; break;
        case "Full Stack": projectEntryPoint = "./bin/www"; break;
        default: projectEntryPoint = "index.js"; break;
    }

    // Create an object to represent package.json
    const pkg = {
        name: projectName,
        version: projectVersion,
        type: projectType.toLowerCase(),
        private: projectPrivacy === 'Private',
        description: projectDescription,
        main: projectEntryPoint,
        scripts: {
            dev: `NODE_ENV=development DEBUG=${projectDebugIdentifer}:* ./node_modules/nodemon/bin/nodemon.js ${projectEntryPoint}`,
            start: `NODE_ENV=production node ${projectEntryPoint}`,
            test: `NODE_ENV=test DEBUG=${projectDebugIdentifer}:* node ${projectEntryPoint}`
        },
        keywords: [],
        author: projectAuthor,
        licence: projectLicence,
        dependencies: {},
        devDependencies: {},
        _moduleAliases: {
            root: ".",
        },
    };

    // Create an object to represent .env.sample or .env
    const env = {

    }

    // Create an object to represent [name].code-workspace
    const cw = {
        folders: [{ path: "." }],
        settings: {}
    }

    // Generic Additional Features
    pkg.dependencies["debug"] = versions.get("debug");
    pkg.dependencies["dotenv"] = versions.get("dotenv");
    pkg.dependencies["module-alias"] = versions.get("module-alias");
    pkg.devDependencies["nodemon"] = versions.get("nodemon");

    // Sequelize Support
    if (projectFeatures.includes('sequelize')) {
        // Include Sequelize Dependencies
        pkg.dependencies["sequelize"] = versions.get("sequelize");
        pkg.devDependencies["sequelize-cli"] = versions.get("sequelize-cli");

        // Specify available / allowed dialects
        const availableDialects = ['SQLite', 'MySQL']

        const {
            sequelizeDevelopmentDatabase,
            sequelizeTestDatabase,
            sequelizeProductionDatabase
        } = await inquirer.prompt([
            {
                type: 'list',
                name: 'sequelizeDevelopmentDatabase',
                message: 'Development Database:',
                choices: availableDialects,
                default: 'SQLite'
            },
            {
                type: 'list',
                name: 'sequelizeTestDatabase',
                message: 'Test Database:',
                choices: availableDialects,
                default: 'SQLite'
            },
            {
                type: 'list',
                name: 'sequelizeProductionDatabase',
                message: 'Production Database:',
                choices: availableDialects,
                default: 'MySQL'
            },
        ]);

        // Handle Dialect Dependencies
        var dialects = [sequelizeDevelopmentDatabase, sequelizeTestDatabase, sequelizeProductionDatabase]
        if (dialects.includes('MySQL')) pkg.dependencies["mysql2"] = versions.get("mysql2");
        if (dialects.includes('SQLite')) pkg.dependencies["sqlite3"] = versions.get("sqlite3");

        // TODO: gitignore .sqlite if any dialect is SQLite
    }

    // Jest Support
    if (projectFeatures.includes('jest')) {
        // Include Jest Dependencies
        pkg.devDependencies["jest"] = versions.get("jest");
    }

    /**
     * File Writing / Output Phase
     */
    console.log('Starting Generation...');

    // Make Project Directory
    fs.mkdirSync(projectPath, { recursive: true });

    // Write package.json
    fs.writeFileSync(path.join(projectPath, 'package.json'), JSON.stringify(pkg));

    // Write .code-workspace
    fs.writeFileSync(path.join(projectPath, `${path.basename(projectPath)}.code-workspace`), JSON.stringify(cw));
}