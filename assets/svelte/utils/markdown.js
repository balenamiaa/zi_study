import { marked } from 'marked';


marked.setOptions({
    gfm: true,
    breaks: true,
    headerIds: false,
    mangle: false
});

export function parseMarkdown(text) {
    if (!text) return '';
    return marked.parse(text);
} 