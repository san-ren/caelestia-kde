pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    readonly property string layoutPath: `${Paths.data}/launcher_favourites.json`

    property bool loaded: false
    property var entries: []

    signal changed()

    function appKey(id: string): string {
        return `a/${id}`;
    }

    function folderKey(id: string): string {
        return `g/${id}`;
    }

    function keyOf(entry: var): string {
        return entry.kind === "folder" ? folderKey(entry.id) : appKey(entry.id);
    }

    function newFolderId(): string {
        let id;
        do
            id = `f${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`;
        while (entries.some(e => e.kind === "folder" && e.id === id));
        return id;
    }

    function folderById(id: string): var {
        return entries.find(e => e.kind === "folder" && e.id === id) ?? null;
    }

    function appIds(): var {
        const out = [];
        for (const e of entries) {
            if (e.kind === "folder")
                out.push(...e.apps);
            else
                out.push(e.id);
        }
        return out;
    }

    function sameEntries(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            const x = a[i];
            const y = b[i];
            if (x.kind !== y.kind || x.id !== y.id || (x.name ?? "") !== (y.name ?? ""))
                return false;
            const xa = x.apps ?? [];
            const ya = y.apps ?? [];
            if (xa.length !== ya.length)
                return false;
            for (let j = 0; j < xa.length; j++)
                if (xa[j] !== ya[j])
                    return false;
        }
        return true;
    }

    function setEntries(next: var): void {
        if (sameEntries(next, entries))
            return;
        entries = next;
        changed();
        scheduleSave();
    }

    function reconcile(appIds: var): void {
        const ids = appIds ?? [];
        const favSet = new Set(ids);
        const seen = new Set();
        const next = [];
        for (const e of entries) {
            if (e.kind === "folder") {
                const apps = e.apps.filter(a => favSet.has(a) && !seen.has(a));
                for (const a of apps)
                    seen.add(a);
                if (apps.length >= 2)
                    next.push({ kind: "folder", id: e.id, name: e.name, apps });
                else if (apps.length === 1)
                    next.push({ kind: "app", id: apps[0] });
            } else if (favSet.has(e.id) && !seen.has(e.id)) {
                next.push({ kind: "app", id: e.id });
                seen.add(e.id);
            }
        }
        for (const id of ids) {
            if (seen.has(id))
                continue;
            next.push({ kind: "app", id });
            seen.add(id);
        }
        setEntries(next);
    }

    function setOrder(keys: var): void {
        const byKey = {};
        for (const e of entries)
            byKey[keyOf(e)] = e;
        const next = [];
        for (const k of keys) {
            if (byKey[k]) {
                next.push(byKey[k]);
                delete byKey[k];
            }
        }
        for (const k in byKey)
            next.push(byKey[k]);
        setEntries(next);
    }

    function makeFolder(sourceKeys: var, targetKey: string): void {
        const isAppKey = k => k.slice(0, 2) === "a/";
        if (!isAppKey(targetKey) || !sourceKeys.every(isAppKey))
            return;
        const sourceIds = sourceKeys.map(k => k.slice(2));
        const targetId = targetKey.slice(2);
        if (sourceIds.indexOf(targetId) !== -1)
            return;
        const targetIndex = entries.findIndex(e => keyOf(e) === targetKey);
        if (targetIndex === -1)
            return;
        const removed = e => sourceKeys.indexOf(keyOf(e)) !== -1 || keyOf(e) === targetKey;
        const next = entries.filter(e => !removed(e));
        const apps = sourceIds.filter(id => entries.some(e => e.kind === "app" && e.id === id));
        apps.unshift(targetId);
        let insert = 0;
        for (let i = 0; i < targetIndex; i++)
            if (!removed(entries[i]))
                insert++;
        next.splice(insert, 0, {
            kind: "folder",
            id: newFolderId(),
            name: qsTr("Folder"),
            apps
        });
        setEntries(next);
    }

    function renameFolder(id: string, name: string): void {
        setEntries(entries.map(e => e.kind === "folder" && e.id === id ? Object.assign({}, e, { name }) : e));
    }

    function ungroup(id: string): void {
        const index = entries.findIndex(e => e.kind === "folder" && e.id === id);
        if (index === -1)
            return;
        const folder = entries[index];
        const next = entries.slice();
        next.splice(index, 1, ...folder.apps.map(a => ({ kind: "app", id: a })));
        setEntries(next);
    }

    function setMemberOrder(folderId: string, ids: var): void {
        const folder = folderById(folderId);
        if (!folder)
            return;
        const valid = ids.filter(id => folder.apps.indexOf(id) !== -1);
        for (const id of folder.apps)
            if (valid.indexOf(id) === -1)
                valid.push(id);
        setEntries(entries.map(e => e.kind === "folder" && e.id === folderId ? Object.assign({}, e, { apps: valid }) : e));
    }

    function moveOut(folderId: string, key: string, toIndex: int): void {
        const folder = folderById(folderId);
        if (!folder || folder.apps.indexOf(key) === -1)
            return;
        const remaining = folder.apps.filter(a => a !== key);
        const folderIndex = entries.findIndex(e => e.kind === "folder" && e.id === folderId);
        const next = entries.slice();
        if (remaining.length >= 2) {
            next[folderIndex] = Object.assign({}, folder, { apps: remaining });
            next.splice(toIndex, 0, { kind: "app", id: key });
        } else {
            next.splice(folderIndex, 1, ...remaining.map(a => ({ kind: "app", id: a })));
            next.splice(toIndex, 0, { kind: "app", id: key });
        }
        setEntries(next);
    }

    function scheduleSave(): void {
        if (loaded)
            saveTimer.restart();
    }

    function serialise(): string {
        return JSON.stringify({ version: 1, entries });
    }

    function parseLayout(text: string): void {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            data = null;
        }
        const next = [];
        const raw = data && Array.isArray(data.entries) ? data.entries : [];
        for (const e of raw) {
            if (!e || typeof e !== "object")
                continue;
            if (e.kind === "folder" && typeof e.id === "string" && Array.isArray(e.apps))
                next.push({ kind: "folder", id: e.id, name: String(e.name ?? ""), apps: e.apps.filter(a => typeof a === "string") });
            else if (typeof e.id === "string")
                next.push({ kind: "app", id: e.id });
        }
        entries = next;
        loaded = true;
        changed();
    }

    Timer {
        id: saveTimer

        interval: 400
        onTriggered: layoutFile.setText(root.serialise())
    }

    FileView {
        id: layoutFile

        path: root.layoutPath
        printErrors: false
        onLoaded: root.parseLayout(text())
        onLoadFailed: root.parseLayout("")
    }
}
