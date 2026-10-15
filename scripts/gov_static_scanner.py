#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 高速静的コード解析エンジン (GovStaticScanner)
========================================================================
lib/ 配下の全 Dart ファイル（800+ ファイル）をメモリキャッシュし、
正規表現パターンやキーワードマッチ、構文規約をミリ秒単位（~0.1s）で
高速に一括検査するためのガバナンス共通解析エンジン。
"""

import os
import re
from typing import Dict, List, Optional, Pattern, Tuple


class GovStaticScanner:
    """プロジェクト全体の Dart ファイルを走査・解析する高速エンジン。"""

    _instance: Optional["GovStaticScanner"] = None

    def __init__(self, root_dir: Optional[str] = None):
        if root_dir is None:
            # プロジェクトルートの自動検出
            script_dir = os.path.dirname(os.path.abspath(__file__))
            root_dir = os.path.dirname(script_dir)
        self.root_dir = root_dir
        self.lib_dir = os.path.join(root_dir, "lib")
        self.test_dir = os.path.join(root_dir, "test")

        # ファイルキャッシュ: {rel_path: content}
        self._lib_files: Optional[Dict[str, str]] = None
        self._test_files: Optional[Dict[str, str]] = None

    @classmethod
    def get_instance(cls, root_dir: Optional[str] = None) -> "GovStaticScanner":
        if cls._instance is None:
            cls._instance = cls(root_dir)
        return cls._instance

    def get_lib_files(self, exclude_generated: bool = True) -> Dict[str, str]:
        """lib/ 配下の全 Dart ファイルの内容をロード（初回のみキャッシュ）。"""
        if self._lib_files is None:
            self._lib_files = {}
            for root, _, filenames in os.walk(self.lib_dir):
                for f in filenames:
                    if not f.endswith(".dart"):
                        continue
                    if exclude_generated and (f.endswith(".g.dart") or f.endswith(".freezed.dart")):
                        continue
                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, self.root_dir).replace("\\", "/")
                    try:
                        with open(full_path, "r", encoding="utf-8", errors="ignore") as fp:
                            self._lib_files[rel_path] = fp.read()
                    except Exception:
                        pass
        return self._lib_files

    def get_test_files(self) -> Dict[str, str]:
        """test/ 配下の全 Dart ファイルの内容をロード（初回のみキャッシュ）。"""
        if self._test_files is None:
            self._test_files = {}
            for root, _, filenames in os.walk(self.test_dir):
                for f in filenames:
                    if not f.endswith(".dart"):
                        continue
                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, self.root_dir).replace("\\", "/")
                    try:
                        with open(full_path, "r", encoding="utf-8", errors="ignore") as fp:
                            self._test_files[rel_path] = fp.read()
                    except Exception:
                        pass
        return self._test_files

    def find_violations(
        self,
        pattern: Pattern,
        exclude_files: Optional[List[str]] = None,
        target_files: Optional[List[str]] = None,
        in_test: bool = False,
    ) -> List[Tuple[str, int, str]]:
        """
        指定した正規表現パターンに合致する違反を高速スキャン。
        戻り値: [(ファイル相対パス, 行番号, マッチした行の内容)]
        """
        files = self.get_test_files() if in_test else self.get_lib_files()
        exclude_set = set(exclude_files or [])
        violations = []

        for rel_path, content in files.items():
            if target_files and not any(rel_path.startswith(t) or rel_path == t for t in target_files):
                continue
            if any(rel_path.endswith(ex) or rel_path == ex for ex in exclude_set):
                continue

            if not pattern.search(content):
                continue

            # 行単位で詳細特定
            lines = content.splitlines()
            for line_idx, line in enumerate(lines, 1):
                if pattern.search(line):
                    violations.append((rel_path, line_idx, line.strip()))

    def read_file(self, rel_path: str) -> str:
        """指定された相対パスのファイル内容を返す。存在しない場合は空文字。"""
        content = get_file_content(rel_path)
        return content if content is not None else ""


def get_scanner() -> GovStaticScanner:
    return GovStaticScanner.get_instance()


def get_file_content(rel_path: str) -> Optional[str]:
    """プロジェクト相対パスのファイル内容を取得（キャッシュ優先）。"""
    scanner = get_scanner()
    if rel_path.startswith("lib/"):
        files = scanner.get_lib_files(exclude_generated=False)
        if rel_path in files:
            return files[rel_path]
    elif rel_path.startswith("test/"):
        files = scanner.get_test_files()
        if rel_path in files:
            return files[rel_path]
    
    # キャッシュ外（設定ファイルや個別ファイル）
    full_path = os.path.join(scanner.root_dir, rel_path)
    if os.path.exists(full_path):
        try:
            with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                return f.read()
        except Exception:
            return None
    return None


if __name__ == "__main__":
    import time

    start = time.time()
    scanner = GovStaticScanner()
    lib_files = scanner.get_lib_files()
    duration = time.time() - start
    print(f"Loaded {len(lib_files)} Dart files in {duration:.3f}s")

