/**
 * VScoder Editor Bundle — CodeMirror 6
 * Full-featured code editor with Flutter <-> JS bidirectional bridge
 * Supports 25+ languages with unique per-language themes
 */

import {
  EditorView, keymap, lineNumbers, highlightActiveLineGutter,
  highlightSpecialChars, drawSelection, dropCursor,
  rectangularSelection, crosshairCursor, highlightActiveLine,
  placeholder, ViewPlugin, ViewUpdate
} from '@codemirror/view';

import {
  EditorState, StateEffect, Compartment, Transaction
} from '@codemirror/state';

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

// ── Language imports ──────────────────────────────────────────────────────────
import { javascript } from '@codemirror/lang-javascript';
import { python } from '@codemirror/lang-python';
import { java } from '@codemirror/lang-java';
import { cpp } from '@codemirror/lang-cpp';
import { css } from '@codemirror/lang-css';
import { html } from '@codemirror/lang-html';
import { json } from '@codemirror/lang-json';
import { markdown } from '@codemirror/lang-markdown';
import { php } from '@codemirror/lang-php';
import { rust } from '@codemirror/lang-rust';
import { sql } from '@codemirror/lang-sql';
import { xml } from '@codemirror/lang-xml';
import { yaml } from '@codemirror/lang-yaml';
import { go } from '@codemirror/lang-go';

// Legacy modes for additional language support
import { shell } from '@codemirror/legacy-modes/mode/shell';
import { ruby } from '@codemirror/legacy-modes/mode/ruby';
import { dart } from '@codemirror/legacy-modes/mode/clike';
import { swift } from '@codemirror/legacy-modes/mode/swift';
import { kotlin } from '@codemirror/legacy-modes/mode/clike';
import { r } from '@codemirror/legacy-modes/mode/r';
import { diff } from '@codemirror/legacy-modes/mode/diff';

// ── VScoder Theme ─────────────────────────────────────────────────────────────
const vscoderTheme = EditorView.theme({
  '&': {
    backgroundColor: '#0D1117',
    color: '#E6EDF3',
    fontSize: '14px',
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
  '.cm-cursor, .cm-dropCursor': {
    borderLeftColor: '#58A6FF',
    borderLeftWidth: '2px',
  },
  '&.cm-focused': { outline: 'none' },
  '.cm-activeLine': { backgroundColor: '#161B2280' },
  '.cm-activeLineGutter': {
    backgroundColor: '#161B2280',
    color: '#CDD9E5',
  },
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
  '.cm-foldGutter .cm-gutterElement': {
    padding: '0 4px',
    cursor: 'pointer',
    color: '#484F58',
  },
  '.cm-foldGutter .cm-gutterElement:hover': { color: '#8B949E' },
  '&.cm-focused .cm-selectionBackground, .cm-selectionBackground': {
    backgroundColor: '#264F78',
  },
  '.cm-selectionMatch': { backgroundColor: '#264F7840' },
  '.cm-matchingBracket, .cm-nonmatchingBracket': {
    backgroundColor: '#264F7880',
    outline: '1px solid #58A6FF80',
    borderRadius: '2px',
  },
  '.cm-nonmatchingBracket': {
    backgroundColor: '#F8514920',
    outline: '1px solid #F85149',
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
  '.cm-completionIcon': { marginRight: '8px', opacity: 0.7 },
  '.cm-foldPlaceholder': {
    backgroundColor: '#21262D',
    border: '1px solid #30363D',
    borderRadius: '4px',
    color: '#8B949E',
    padding: '0 6px',
    margin: '0 2px',
  },
  '.cm-searchMatch': {
    backgroundColor: '#F2CC6030',
    outline: '1px solid #F2CC60',
    borderRadius: '2px',
  },
  '.cm-searchMatch.cm-searchMatch-selected': {
    backgroundColor: '#F2CC6060',
  },
  '.cm-panels': {
    backgroundColor: '#161B22',
    borderColor: '#30363D',
  },
  '.cm-panels.cm-panels-top': { borderBottom: '1px solid #30363D' },
  '.cm-panels.cm-panels-bottom': { borderTop: '1px solid #30363D' },
  '.cm-search': {
    padding: '8px 12px',
    color: '#E6EDF3',
  },
  '.cm-search input': {
    backgroundColor: '#0D1117',
    border: '1px solid #30363D',
    borderRadius: '6px',
    color: '#E6EDF3',
    padding: '4px 8px',
    fontSize: '13px',
    fontFamily: "'JetBrains Mono', monospace",
  },
  '.cm-search input:focus': {
    outline: 'none',
    borderColor: '#58A6FF',
  },
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
  '.cm-search label': { color: '#8B949E', fontSize: '12px', marginLeft: '8px' },
}, { dark: true });

// ── VScoder Syntax Highlight Scheme ──────────────────────────────────────────
const vscoderHighlight = HighlightStyle.define([
  { tag: [t.keyword, t.controlKeyword, t.operatorKeyword, t.moduleKeyword, t.definitionKeyword],
    color: '#FF7B72', fontWeight: '500' },
  { tag: [t.modifier], color: '#FF7B72' },
  { tag: t.name, color: '#E6EDF3' },
  { tag: t.propertyName, color: '#79C0FF' },
  { tag: [t.variableName, t.derefOperator], color: '#FFA657' },
  { tag: t.definition(t.variableName), color: '#FFA657' },
  { tag: [t.function(t.variableName), t.function(t.propertyName)], color: '#D2A8FF' },
  { tag: t.definition(t.function(t.variableName)), color: '#D2A8FF' },
  { tag: [t.className, t.definition(t.typeName), t.typeName], color: '#F0883E' },
  { tag: t.namespace, color: '#F0883E' },
  { tag: t.tagName, color: '#7EE787' },
  { tag: t.attributeName, color: '#79C0FF' },
  { tag: t.attributeValue, color: '#A5D6FF' },
  { tag: [t.string, t.special(t.string)], color: '#A5D6FF' },
  { tag: t.regexp, color: '#A5D6FF' },
  { tag: [t.number, t.integer, t.float], color: '#79C0FF' },
  { tag: [t.bool, t.null], color: '#79C0FF', fontWeight: '500' },
  { tag: t.operator, color: '#FF7B72' },
  { tag: t.punctuation, color: '#CDD9E5' },
  { tag: t.bracket, color: '#CDD9E5' },
  { tag: [t.lineComment, t.blockComment, t.docComment],
    color: '#8B949E', fontStyle: 'italic' },
  { tag: t.meta, color: '#8B949E' },
  { tag: t.invalid, color: '#F85149', textDecoration: 'underline wavy' },
  { tag: t.inserted, color: '#3FB950' },
  { tag: t.deleted, color: '#F85149' },
  { tag: t.changed, color: '#FFA657' },
  { tag: t.escape, color: '#79C0FF' },
  { tag: t.url, color: '#A5D6FF', textDecoration: 'underline' },
  { tag: t.heading, color: '#79C0FF', fontWeight: '700' },
  { tag: t.quote, color: '#8B949E', fontStyle: 'italic' },
  { tag: t.emphasis, fontStyle: 'italic' },
  { tag: t.strong, fontWeight: '700' },
  { tag: t.link, color: '#A5D6FF', textDecoration: 'underline' },
  { tag: t.atom, color: '#79C0FF' },
  { tag: t.self, color: '#FF7B72' },
  { tag: t.labelName, color: '#FFA657' },
]);

// ── Language map ──────────────────────────────────────────────────────────────
function getLanguageExtension(lang) {
  const map = {
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
    yaml:       yaml(),
    yml:        yaml(),
    go:         go(),
    shell:      StreamLanguage.define(shell),
    bash:       StreamLanguage.define(shell),
    sh:         StreamLanguage.define(shell),
    ruby:       StreamLanguage.define(ruby),
    rb:         StreamLanguage.define(ruby),
    dart:       StreamLanguage.define(dart),
    swift:      StreamLanguage.define(swift),
    r:          StreamLanguage.define(r),
    diff:       StreamLanguage.define(diff),
  };
  return map[lang?.toLowerCase()] || null;
}

// ── Compartments (allow runtime reconfiguration) ───────────────────────────
const languageCompartment = new Compartment();
const tabSizeCompartment   = new Compartment();
const fontSizeCompartment  = new Compartment();
const readOnlyCompartment  = new Compartment();

// ── Editor state ──────────────────────────────────────────────────────────────
let editorView = null;
let currentLanguage = 'javascript';
let isDirty = false;
let isReady = false;
let changeDebounceTimer = null;

// ── Flutter bridge helper ─────────────────────────────────────────────────────
function callFlutter(handler, ...args) {
  try {
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler(handler, ...args);
    }
  } catch (e) {
    console.warn('[VScoder] Flutter handler not available:', handler, e);
  }
}

// ── Create editor ─────────────────────────────────────────────────────────────
function createEditor(initialContent = '', language = 'javascript') {
  currentLanguage = language;
  const langExt = getLanguageExtension(language);

  const extensions = [
    // Core
    lineNumbers(),
    highlightActiveLineGutter(),
    highlightSpecialChars(),
    history(),
    foldGutter({
      openText: '▾',
      closedText: '▸',
    }),
    drawSelection(),
    dropCursor(),
    EditorState.allowMultipleSelections.of(true),
    indentOnInput(),
    bracketMatching(),
    closeBrackets(),
    autocompletion({
      closeOnBlur: false,
      activateOnTyping: true,
      maxRenderedOptions: 10,
    }),
    rectangularSelection(),
    crosshairCursor(),
    highlightActiveLine(),
    highlightSelectionMatches(),

    // Search panel
    keymap.of([
      ...closeBracketsKeymap,
      ...defaultKeymap,
      ...searchKeymap,
      ...historyKeymap,
      ...foldKeymap,
      ...completionKeymap,
      ...lintKeymap,
      indentWithTab,
    ]),

    // Visual
    vscoderTheme,
    syntaxHighlighting(vscoderHighlight),

    // Compartments
    languageCompartment.of(langExt ? langExt : []),
    tabSizeCompartment.of(EditorState.tabSize.of(2)),
    fontSizeCompartment.of(EditorView.theme({ '&': { fontSize: '14px' } })),
    readOnlyCompartment.of(EditorState.readOnly.of(false)),

    // Placeholder
    placeholder('// Start coding...'),

    // Change listener
    EditorView.updateListener.of((update) => {
      if (update.docChanged) {
        isDirty = true;
        clearTimeout(changeDebounceTimer);
        changeDebounceTimer = setTimeout(() => {
          const content = editorView.state.doc.toString();
          callFlutter('onContentChange', content, isDirty);
        }, 150);
      }
      if (update.selectionSet) {
        const sel = update.state.selection.main;
        const line = update.state.doc.lineAt(sel.head);
        const col  = sel.head - line.from;
        callFlutter('onCursorMove', line.number, col + 1);

        if (!sel.empty) {
          const selectedText = update.state.sliceDoc(sel.from, sel.to);
          callFlutter('onSelectionChange', selectedText);
        }
      }
    }),

    // Keyboard shortcut to open search
    keymap.of([{
      key: 'Ctrl-f',
      run: openSearchPanel,
      preventDefault: true,
    }]),
  ];

  const state = EditorState.create({
    doc: initialContent,
    extensions,
  });

  if (editorView) {
    editorView.destroy();
  }

  editorView = new EditorView({
    state,
    parent: document.getElementById('editor'),
  });

  isDirty = false;
  isReady = true;
  callFlutter('onEditorReady');
}

// ── Public API (called from Flutter via evaluateJavascript) ───────────────────
window.vsEditor = {

  // Set full content and language
  setContent(content, language) {
    if (!editorView) { createEditor(content, language); return; }

    const langExt = getLanguageExtension(language);
    currentLanguage = language || currentLanguage;

    editorView.dispatch({
      changes: {
        from: 0,
        to: editorView.state.doc.length,
        insert: content || '',
      },
      effects: langExt
        ? [languageCompartment.reconfigure(langExt)]
        : [],
    });
    isDirty = false;
  },

  // Get content
  getContent() {
    return editorView ? editorView.state.doc.toString() : '';
  },

  // Set language only
  setLanguage(language) {
    if (!editorView) return;
    const langExt = getLanguageExtension(language);
    if (!langExt) return;
    currentLanguage = language;
    editorView.dispatch({
      effects: languageCompartment.reconfigure(langExt),
    });
  },

  // Insert text at cursor position
  insert(text) {
    if (!editorView) return;
    const { from, to } = editorView.state.selection.main;
    editorView.dispatch({
      changes: { from, to, insert: text },
      selection: { anchor: from + text.length },
    });
    editorView.focus();
  },

  // Editing commands
  undo() { if (editorView) undo(editorView); },
  redo() { if (editorView) redo(editorView); },

  selectAll() {
    if (!editorView) return;
    editorView.dispatch({
      selection: { anchor: 0, head: editorView.state.doc.length },
    });
    editorView.focus();
  },

  // Copy selection to clipboard
  copy() {
    if (!editorView) return;
    const sel = editorView.state.selection.main;
    const text = editorView.state.sliceDoc(sel.from, sel.to);
    if (text) navigator.clipboard?.writeText(text);
  },

  // Paste from clipboard
  async paste() {
    if (!editorView) return;
    try {
      const text = await navigator.clipboard?.readText() || '';
      this.insert(text);
    } catch (e) { /* clipboard not available */ }
  },

  // Set cursor position (1-based line, col)
  setCursor(line, col) {
    if (!editorView) return;
    try {
      const lineInfo = editorView.state.doc.line(Math.max(1, line));
      const pos = Math.min(lineInfo.from + (col - 1), lineInfo.to);
      editorView.dispatch({ selection: { anchor: pos } });
      editorView.scrollIntoView({ index: pos, y: 'center' });
    } catch (e) {}
  },

  // Get cursor position
  getCursorPosition() {
    if (!editorView) return { line: 1, col: 1 };
    const sel  = editorView.state.selection.main;
    const line = editorView.state.doc.lineAt(sel.head);
    return { line: line.number, col: sel.head - line.from + 1 };
  },

  // Set font size
  setFontSize(size) {
    if (!editorView) return;
    editorView.dispatch({
      effects: fontSizeCompartment.reconfigure(
        EditorView.theme({ '&': { fontSize: `${size}px` } })
      ),
    });
  },

  // Set tab size
  setTabSize(size) {
    if (!editorView) return;
    editorView.dispatch({
      effects: tabSizeCompartment.reconfigure(EditorState.tabSize.of(size)),
    });
  },

  // Set read-only mode
  setReadOnly(readOnly) {
    if (!editorView) return;
    editorView.dispatch({
      effects: readOnlyCompartment.reconfigure(EditorState.readOnly.of(readOnly)),
    });
  },

  // Open search panel
  openSearch() {
    if (!editorView) return;
    openSearchPanel(editorView);
  },

  // Focus
  focus() { editorView?.focus(); },

  // Mark clean (after save)
  markClean() { isDirty = false; },

  // Check dirty state
  isDirty() { return isDirty; },

  // Check ready
  isReady() { return isReady; },

  // Get line count
  getLineCount() {
    return editorView ? editorView.state.doc.lines : 0;
  },

  // Go to line
  goToLine(lineNumber) {
    this.setCursor(lineNumber, 1);
  },

  // Format (basic indent normalization)
  format() {
    if (!editorView) return;
    // For now, just re-trigger syntax; proper formatting needs prettier per-language
    callFlutter('onFormatRequest', currentLanguage);
  },
};

// ── Initialize on DOM ready ────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  createEditor('', 'javascript');
});

// Also init immediately if DOM is already ready
if (document.readyState !== 'loading') {
  createEditor('', 'javascript');
}

// ── Capture console errors for the Console panel ──────────────────────────────
const _origError = console.error.bind(console);
const _origWarn  = console.warn.bind(console);
const _origLog   = console.log.bind(console);

console.error = (...args) => {
  _origError(...args);
  callFlutter('onConsoleLog', 'error', args.map(String).join(' '));
};
console.warn = (...args) => {
  _origWarn(...args);
  callFlutter('onConsoleLog', 'warn', args.map(String).join(' '));
};
console.log = (...args) => {
  _origLog(...args);
  callFlutter('onConsoleLog', 'log', args.map(String).join(' '));
};

window.onerror = (msg, src, line, col, err) => {
  callFlutter('onConsoleLog', 'error', `${msg} (${src}:${line}:${col})`);
  return false;
};
