/**
 * VScoder Editor Bundle — CodeMirror 6
 * Full-featured code editor with Flutter <-> JS bidirectional bridge
 */

import {
  EditorView, keymap, lineNumbers, highlightActiveLineGutter,
  highlightSpecialChars, drawSelection, dropCursor,
  rectangularSelection, crosshairCursor, highlightActiveLine,
  placeholder
} from '@codemirror/view';

import { EditorState, StateEffect, Compartment } from '@codemirror/state';

import {
  defaultKeymap, history, historyKeymap, indentWithTab,
  selectAll, undo, redo
} from '@codemirror/commands';

import {
  bracketMatching, foldGutter, foldKeymap,
  indentOnInput, syntaxHighlighting, HighlightStyle,
  StreamLanguage
} from '@codemirror/language';

import { tags as t } from '@lezer/highlight';
import { autocompletion, completionKeymap, closeBrackets, closeBracketsKeymap } from '@codemirror/autocomplete';
import { searchKeymap, highlightSelectionMatches, openSearchPanel } from '@codemirror/search';
import { lintKeymap } from '@codemirror/lint';

// ── Official language packages (all confirmed stable on npm) ──────────────────
import { javascript } from '@codemirror/lang-javascript';
import { python }     from '@codemirror/lang-python';
import { java }       from '@codemirror/lang-java';
import { cpp }        from '@codemirror/lang-cpp';
import { css }        from '@codemirror/lang-css';
import { html }       from '@codemirror/lang-html';
import { json }       from '@codemirror/lang-json';
import { markdown }   from '@codemirror/lang-markdown';
import { php }        from '@codemirror/lang-php';
import { rust }       from '@codemirror/lang-rust';
import { sql }        from '@codemirror/lang-sql';
import { xml }        from '@codemirror/lang-xml';

// ── Legacy modes (covers Go, YAML, Shell, Ruby, Swift, Dart, R, etc.) ────────
import { go }     from '@codemirror/legacy-modes/mode/go';
import { yaml }   from '@codemirror/legacy-modes/mode/yaml';
import { shell }  from '@codemirror/legacy-modes/mode/shell';
import { ruby }   from '@codemirror/legacy-modes/mode/ruby';
import { swift }  from '@codemirror/legacy-modes/mode/swift';
import { r }      from '@codemirror/legacy-modes/mode/r';
import { diff }   from '@codemirror/legacy-modes/mode/diff';
import { toml }   from '@codemirror/legacy-modes/mode/toml';
// Dart and Kotlin use the C-like mode
import { clike }  from '@codemirror/legacy-modes/mode/clike';

// ── VScoder Dark Theme ────────────────────────────────────────────────────────
const vscoderTheme = EditorView.theme({
  '&': {
    backgroundColor: '#0D1117',
    color: '#E6EDF3',
    height: '100%',
    width: '100%',
  },
  '.cm-scroller': {
    fontFamily: "'JetBrains Mono', 'Droid Sans Mono', 'Courier New', monospace",
    lineHeight: '1.65',
    overflow: 'auto',
    height: '100%',
  },
  '.cm-content': {
    caretColor: '#58A6FF',
    padding: '12px 0',
    minHeight: '100%',
  },
  '.cm-cursor': { borderLeftColor: '#58A6FF', borderLeftWidth: '2px' },
  '&.cm-focused': { outline: 'none' },
  '.cm-activeLine': { backgroundColor: '#161B2280' },
  '.cm-activeLineGutter': { backgroundColor: '#161B2280', color: '#CDD9E5' },
  '.cm-gutters': {
    backgroundColor: '#0D1117',
    color: '#484F58',
    border: 'none',
    borderRight: '1px solid #21262D',
    minWidth: '48px',
  },
  '.cm-lineNumbers .cm-gutterElement': {
    padding: '0 12px 0 8px',
    minWidth: '36px',
    userSelect: 'none',
  },
  '&.cm-focused .cm-selectionBackground, .cm-selectionBackground': {
    backgroundColor: '#264F78',
  },
  '.cm-matchingBracket': {
    backgroundColor: '#264F7880',
    outline: '1px solid #58A6FF80',
    borderRadius: '2px',
  },
  '.cm-tooltip': {
    backgroundColor: '#1C2128',
    border: '1px solid #30363D',
    borderRadius: '8px',
    boxShadow: '0 8px 24px rgba(1,4,9,0.8)',
  },
  '.cm-tooltip.cm-tooltip-autocomplete > ul': {
    fontFamily: "'JetBrains Mono', monospace",
    fontSize: '13px',
    maxHeight: '240px',
  },
  '.cm-tooltip.cm-tooltip-autocomplete > ul > li': {
    padding: '5px 14px',
    color: '#CDD9E5',
  },
  '.cm-tooltip.cm-tooltip-autocomplete > ul > li[aria-selected]': {
    backgroundColor: '#264F78',
    color: '#E6EDF3',
  },
  '.cm-searchMatch': {
    backgroundColor: '#F2CC6030',
    outline: '1px solid #F2CC60',
    borderRadius: '2px',
  },
  '.cm-searchMatch.cm-searchMatch-selected': { backgroundColor: '#F2CC6060' },
  '.cm-panels': { backgroundColor: '#161B22', borderColor: '#30363D' },
  '.cm-panels.cm-panels-top': { borderBottom: '1px solid #30363D' },
  '.cm-search': { padding: '8px 12px', color: '#E6EDF3' },
  '.cm-search input': {
    backgroundColor: '#0D1117',
    border: '1px solid #30363D',
    borderRadius: '6px',
    color: '#E6EDF3',
    padding: '4px 8px',
    fontSize: '13px',
    fontFamily: "'JetBrains Mono', monospace",
  },
  '.cm-search input:focus': { outline: 'none', borderColor: '#58A6FF' },
  '.cm-search button': {
    backgroundColor: '#21262D',
    border: '1px solid #30363D',
    borderRadius: '6px',
    color: '#CDD9E5',
    cursor: 'pointer',
    padding: '4px 10px',
    fontSize: '12px',
    marginLeft: '4px',
  },
  '.cm-search button:hover': { backgroundColor: '#30363D' },
  '.cm-foldPlaceholder': {
    backgroundColor: '#21262D',
    border: '1px solid #30363D',
    borderRadius: '4px',
    color: '#8B949E',
    padding: '0 6px',
  },
}, { dark: true });

// ── VScoder Syntax Highlight Colors ──────────────────────────────────────────
const vscoderHighlight = HighlightStyle.define([
  { tag: [t.keyword, t.controlKeyword, t.operatorKeyword, t.moduleKeyword, t.definitionKeyword],
    color: '#FF7B72', fontWeight: '500' },
  { tag: t.name,                                     color: '#E6EDF3' },
  { tag: t.propertyName,                             color: '#79C0FF' },
  { tag: [t.variableName],                           color: '#FFA657' },
  { tag: t.definition(t.variableName),               color: '#FFA657' },
  { tag: [t.function(t.variableName), t.function(t.propertyName)], color: '#D2A8FF' },
  { tag: [t.className, t.typeName],                  color: '#F0883E' },
  { tag: t.tagName,                                  color: '#7EE787' },
  { tag: t.attributeName,                            color: '#79C0FF' },
  { tag: t.attributeValue,                           color: '#A5D6FF' },
  { tag: [t.string, t.special(t.string)],            color: '#A5D6FF' },
  { tag: t.regexp,                                   color: '#A5D6FF' },
  { tag: [t.number, t.integer, t.float],             color: '#79C0FF' },
  { tag: [t.bool, t.null],                           color: '#79C0FF', fontWeight: '500' },
  { tag: t.operator,                                 color: '#FF7B72' },
  { tag: [t.lineComment, t.blockComment, t.docComment],
    color: '#8B949E', fontStyle: 'italic' },
  { tag: t.meta,                                     color: '#8B949E' },
  { tag: t.invalid,         color: '#F85149', textDecoration: 'underline wavy' },
  { tag: t.inserted,                                 color: '#3FB950' },
  { tag: t.deleted,                                  color: '#F85149' },
  { tag: t.heading,                                  color: '#79C0FF', fontWeight: '700' },
  { tag: t.url,             color: '#A5D6FF', textDecoration: 'underline' },
  { tag: t.emphasis,                                 fontStyle: 'italic' },
  { tag: t.strong,                                   fontWeight: '700' },
]);

// ── Dart mode definition (C-like base) ────────────────────────────────────────
const dartMode = clike({
  keywords: 'abstract as assert async await break case catch class const continue '
          + 'covariant default deferred do dynamic else enum export extends extension '
          + 'external factory false final finally for Function get hide if implements '
          + 'import in interface is late library mixin new null on operator part required '
          + 'rethrow return sealed set show static super switch sync this throw true try '
          + 'typedef var void while with yield',
  blockKeywords: 'catch class do else finally for if switch try while',
  defKeywords: 'class extension function interface mixin',
  typeFirstDefinitions: true,
  atoms: 'true false null',
  number: /^(?:0x[a-f\d]+|(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?)/i,
  name: 'dart',
});

const kotlinMode = clike({
  keywords: 'abstract as break by catch class companion const constructor continue '
          + 'crossinline data delegate do dynamic else enum expect external false '
          + 'field file final finally for fun get if import in infix init inline '
          + 'inner interface internal is it lateinit noinline null object open operator '
          + 'out override package private protected public reified return sealed set '
          + 'super suspend tailrec this throw true try typealias typeof val var vararg '
          + 'when where while',
  blockKeywords: 'catch class do else finally for if try while',
  defKeywords: 'class fun interface object',
  typeFirstDefinitions: true,
  atoms: 'true false null',
  name: 'kotlin',
});

// ── Compartments ──────────────────────────────────────────────────────────────
const languageCompartment = new Compartment();
const tabSizeCompartment  = new Compartment();
const fontSizeCompartment = new Compartment();
const readOnlyCompartment = new Compartment();

// ── Language resolver ─────────────────────────────────────────────────────────
function getLanguageExtension(lang) {
  if (!lang) return null;
  const l = lang.toLowerCase();
  const map = {
    // Official packages
    javascript: javascript(),
    js:         javascript(),
    jsx:        javascript({ jsx: true }),
    typescript: javascript({ typescript: true }),
    ts:         javascript({ typescript: true }),
    tsx:        javascript({ jsx: true, typescript: true }),
    python:     python(),
    py:         python(),
    java:       java(),
    cpp:        cpp(),
    'c++':      cpp(),
    c:          cpp(),
    css:        css(),
    html:       html(),
    json:       json(),
    markdown:   markdown(),
    md:         markdown(),
    php:        php(),
    rust:       rust(),
    rs:         rust(),
    sql:        sql(),
    xml:        xml(),
    // Legacy modes
    go:         StreamLanguage.define(go),
    yaml:       StreamLanguage.define(yaml),
    yml:        StreamLanguage.define(yaml),
    shell:      StreamLanguage.define(shell),
    bash:       StreamLanguage.define(shell),
    sh:         StreamLanguage.define(shell),
    ruby:       StreamLanguage.define(ruby),
    rb:         StreamLanguage.define(ruby),
    swift:      StreamLanguage.define(swift),
    dart:       StreamLanguage.define(dartMode),
    kotlin:     StreamLanguage.define(kotlinMode),
    kt:         StreamLanguage.define(kotlinMode),
    r:          StreamLanguage.define(r),
    diff:       StreamLanguage.define(diff),
    toml:       StreamLanguage.define(toml),
  };
  return map[l] || null;
}

// ── Editor state ──────────────────────────────────────────────────────────────
let editorView       = null;
let currentLanguage  = 'javascript';
let isDirty          = false;
let isReady          = false;
let changeDebounce   = null;

// ── Flutter bridge ────────────────────────────────────────────────────────────
function callFlutter(handler, ...args) {
  try {
    window.flutter_inappwebview?.callHandler(handler, ...args);
  } catch (e) {}
}

// ── Build editor ──────────────────────────────────────────────────────────────
function buildEditor(doc, lang) {
  currentLanguage = lang || 'javascript';
  const langExt   = getLanguageExtension(currentLanguage);

  const state = EditorState.create({
    doc,
    extensions: [
      lineNumbers(),
      highlightActiveLineGutter(),
      highlightSpecialChars(),
      history(),
      foldGutter({ openText: '▾', closedText: '▸' }),
      drawSelection(),
      dropCursor(),
      EditorState.allowMultipleSelections.of(true),
      indentOnInput(),
      bracketMatching(),
      closeBrackets(),
      autocompletion({ closeOnBlur: false, activateOnTyping: true, maxRenderedOptions: 10 }),
      rectangularSelection(),
      crosshairCursor(),
      highlightActiveLine(),
      highlightSelectionMatches(),
      keymap.of([
        ...closeBracketsKeymap,
        ...defaultKeymap,
        ...searchKeymap,
        ...historyKeymap,
        ...foldKeymap,
        ...completionKeymap,
        ...lintKeymap,
        indentWithTab,
        { key: 'Ctrl-f', run: openSearchPanel, preventDefault: true },
      ]),
      vscoderTheme,
      syntaxHighlighting(vscoderHighlight),
      languageCompartment.of(langExt ? langExt : []),
      tabSizeCompartment.of(EditorState.tabSize.of(2)),
      fontSizeCompartment.of(EditorView.theme({ '&': { fontSize: '14px' } })),
      readOnlyCompartment.of(EditorState.readOnly.of(false)),
      placeholder('// Start coding...'),
      EditorView.updateListener.of((update) => {
        if (update.docChanged) {
          isDirty = true;
          clearTimeout(changeDebounce);
          changeDebounce = setTimeout(() => {
            callFlutter('onContentChange', editorView.state.doc.toString(), isDirty);
          }, 150);
        }
        if (update.selectionSet) {
          const sel  = update.state.selection.main;
          const line = update.state.doc.lineAt(sel.head);
          callFlutter('onCursorMove', line.number, sel.head - line.from + 1);
          if (!sel.empty) {
            callFlutter('onSelectionChange', update.state.sliceDoc(sel.from, sel.to));
          }
        }
      }),
    ],
  });

  if (editorView) editorView.destroy();
  editorView = new EditorView({ state, parent: document.getElementById('editor') });
  isDirty = false;
  isReady = true;
  callFlutter('onEditorReady');
}

// ── Public API ────────────────────────────────────────────────────────────────
window.vsEditor = {
  setContent(content, language) {
    if (!editorView) { buildEditor(content || '', language); return; }
    const langExt = getLanguageExtension(language);
    currentLanguage = language || currentLanguage;
    editorView.dispatch({
      changes: { from: 0, to: editorView.state.doc.length, insert: content || '' },
      effects: langExt ? [languageCompartment.reconfigure(langExt)] : [],
    });
    isDirty = false;
  },

  getContent()          { return editorView ? editorView.state.doc.toString() : ''; },
  setLanguage(lang)     { this.setContent(this.getContent(), lang); },
  undo()                { if (editorView) undo(editorView); },
  redo()                { if (editorView) redo(editorView); },

  insert(text) {
    if (!editorView) return;
    const { from, to } = editorView.state.selection.main;
    editorView.dispatch({ changes: { from, to, insert: text }, selection: { anchor: from + text.length } });
    editorView.focus();
  },

  selectAll() {
    if (!editorView) return;
    editorView.dispatch({ selection: { anchor: 0, head: editorView.state.doc.length } });
    editorView.focus();
  },

  copy() {
    if (!editorView) return;
    const { from, to } = editorView.state.selection.main;
    const text = editorView.state.sliceDoc(from, to);
    if (text) navigator.clipboard?.writeText(text);
  },

  async paste() {
    if (!editorView) return;
    try { this.insert(await navigator.clipboard?.readText() || ''); } catch (e) {}
  },

  setCursor(line, col) {
    if (!editorView) return;
    try {
      const l   = editorView.state.doc.line(Math.max(1, line));
      const pos = Math.min(l.from + Math.max(0, col - 1), l.to);
      editorView.dispatch({ selection: { anchor: pos } });
      editorView.scrollIntoView({ index: pos, y: 'center' });
    } catch (e) {}
  },

  getCursorPosition() {
    if (!editorView) return { line: 1, col: 1 };
    const sel  = editorView.state.selection.main;
    const line = editorView.state.doc.lineAt(sel.head);
    return { line: line.number, col: sel.head - line.from + 1 };
  },

  setFontSize(size) {
    if (!editorView) return;
    editorView.dispatch({
      effects: fontSizeCompartment.reconfigure(
        EditorView.theme({ '&': { fontSize: `${size}px` } })
      ),
    });
  },

  setTabSize(size) {
    if (!editorView) return;
    editorView.dispatch({
      effects: tabSizeCompartment.reconfigure(EditorState.tabSize.of(size)),
    });
  },

  setReadOnly(v) {
    if (!editorView) return;
    editorView.dispatch({
      effects: readOnlyCompartment.reconfigure(EditorState.readOnly.of(v)),
    });
  },

  openSearch() { if (editorView) openSearchPanel(editorView); },
  focus()      { editorView?.focus(); },
  markClean()  { isDirty = false; },
  isDirty()    { return isDirty; },
  isReady()    { return isReady; },
  goToLine(n)  { this.setCursor(n, 1); },
  getLineCount() { return editorView ? editorView.state.doc.lines : 0; },
};

// ── Bootstrap ─────────────────────────────────────────────────────────────────
function init() {
  if (document.getElementById('editor')) {
    buildEditor('', 'javascript');
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

// ── Console bridge ────────────────────────────────────────────────────────────
const _log   = console.log.bind(console);
const _warn  = console.warn.bind(console);
const _error = console.error.bind(console);

console.log   = (...a) => { _log(...a);   callFlutter('onConsoleLog', 'log',   a.map(String).join(' ')); };
console.warn  = (...a) => { _warn(...a);  callFlutter('onConsoleLog', 'warn',  a.map(String).join(' ')); };
console.error = (...a) => { _error(...a); callFlutter('onConsoleLog', 'error', a.map(String).join(' ')); };

window.onerror = (msg, src, line, col) => {
  callFlutter('onConsoleLog', 'error', `${msg} (${src}:${line}:${col})`);
  return false;
};
