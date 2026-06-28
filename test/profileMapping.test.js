'use strict';

// Unit tests for the anthropometric grounding matcher.
// Run with:  npm run test:unit   (node --test test/)
//
// These cover the regression that anchored every metric patient description on
// ANSUR I Male: the male token "m" matched the unit "mm,"/"cm,", and the parser
// was English-only. They use synthetic profile rows so they need no database.

const { test } = require('node:test');
const assert = require('node:assert/strict');

const {
    normGender,
    extractAge,
    ageGroupFromYears,
    profileAgeYears,
    findBestProfileMatch,
} = require('../server/services/profileMapping');

const CANDIDATES = [
    { id: 1, group_name: 'ANSUR I Female 50th Percentile + Hand Survey', country: 'United States', gender: 'female', age_group: 'Adult (Military, 17–40)' },
    { id: 2, group_name: 'ANSUR I Male 50th Percentile + Hand Survey',   country: 'United States', gender: 'male',   age_group: 'Adult (Military, 17–40)' },
    { id: 3, group_name: 'Dutch children KIMA female, age 7',            country: 'Netherlands',   gender: 'female', age_group: '7' },
    { id: 4, group_name: 'Dutch children KIMA female, age 2',            country: 'Netherlands',   gender: 'female', age_group: '2' },
    { id: 5, group_name: 'Dutch elderly female, age 70-74',              country: 'Netherlands',   gender: 'female', age_group: '70-74' },
];

test('normGender: units must NOT be read as male (the regression)', () => {
    assert.equal(normGender('Largura da palma 62 mm, 165 cm, magra'), null);
    assert.equal(normGender('palm 96 mm, 188 cm'), null);
});

test('normGender: multilingual whole words', () => {
    assert.equal(normGender('Mulher adulta, 34 anos'), 'female');
    assert.equal(normGender('Homem de 45 anos'), 'male');
    assert.equal(normGender('woman, slim build'), 'female');
    assert.equal(normGender('menina ginasta'), 'female');
    assert.equal(normGender('hombre mayor'), 'male');
    assert.equal(normGender('Criança de 7 anos'), null); // neutral
});

test('extractAge: EN/PT/ES, and units are not ages', () => {
    assert.equal(extractAge('7 anos'), 7);
    assert.equal(extractAge('34 years old'), 34);
    assert.equal(extractAge('paciente de 72 años'), 72);
    assert.equal(extractAge('188 cm, 96 mm'), null); // heights/lengths are not ages
    assert.equal(extractAge('sem idade indicada'), null);
});

test('ageGroupFromYears buckets', () => {
    assert.equal(ageGroupFromYears(7), 'child');
    assert.equal(ageGroupFromYears(34), 'adult');
    assert.equal(ageGroupFromYears(70), 'elderly');
    assert.equal(ageGroupFromYears(null), null);
});

test('profileAgeYears parses singletons, ranges, open ranges, labels', () => {
    assert.equal(profileAgeYears('7'), 7);
    assert.equal(profileAgeYears('18-30'), 24);
    assert.equal(profileAgeYears('80+'), 85);
    assert.equal(profileAgeYears('65+'), 70);
    assert.equal(profileAgeYears('Adult (Military, 17–40)'), 29);
    assert.equal(profileAgeYears('mixed'), null);
});

test('match: woman → female adult (NOT the male profile)', () => {
    const m = findBestProfileMatch('Mulher adulta, 34 anos, 165 cm, magra', CANDIDATES);
    assert.equal(m.id, 1);
});

test('match: man → male adult', () => {
    const m = findBestProfileMatch('Homem adulto, 45 anos, 188 cm', CANDIDATES);
    assert.equal(m.id, 2);
});

test('match: child age 7 → the age-7 child profile (not age 2)', () => {
    const m = findBestProfileMatch('Criança de 7 anos, mão pequena. Palma 62 mm', CANDIDATES);
    assert.equal(m.id, 3);
});

test('match: a units-only description does not falsely anchor on male', () => {
    const m = findBestProfileMatch('Palma 62 mm, comprimento 56 mm, 165 cm', CANDIDATES);
    // No gender/age signal → score below threshold → no (wrong) match.
    assert.equal(m, null);
});

test('match: LLM-style hints override text parsing', () => {
    const m = findBestProfileMatch('paciente sem termos reconhecíveis', CANDIDATES, { gender: 'female', age: 72 });
    assert.equal(m.id, 5); // elderly female
});
