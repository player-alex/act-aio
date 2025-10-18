from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtGui import QTextDocument, QFont

class TextFormatter(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.latin_font = "Roboto"
        self.korean_font = "Malgun Gothic"
        self.japanese_font = "Meiryo"
        self.chinese_font = "Microsoft YaHei"
        self.debug_mode = False

    @Slot(bool)
    def setDebugMode(self, enabled):
        self.debug_mode = enabled

    @Slot(str, result=str)
    def formatText(self, text):
        """기본 포맷팅"""
        if not text:
            return ""

        result = []
        i = 0

        while i < len(text):
            char = text[i]
            code = ord(char)

            lang_type = self._detect_language(code)
            segment = char
            i += 1

            while i < len(text):
                next_char = text[i]
                next_code = ord(next_char)
                next_lang = self._detect_language(next_code)

                if next_lang == lang_type:
                    segment += next_char
                    i += 1
                else:
                    break

            font_name = self._get_font_for_language(lang_type)
            segment = self._escape_html(segment)

            result.append(f'<span style="font-family: {font_name};">{segment}</span>')

        return ''.join(result)

    @Slot(str, float, float, int, int, result=str)
    def formatTextWithElide(self, text, width_pixels, font_size, max_lines, elide_mode):
        """
        실제 렌더링 너비를 기반으로 텍스트 elide 적용
        """
        if self.debug_mode:
            print(f"\n=== formatTextWithElide ===")
            print(f"Text: '{text[:50]}...' (length: {len(text)})")
            print(f"Width: {width_pixels}px")
            print(f"Font size: {font_size}pt")
            print(f"Max lines: {max_lines}")
            print(f"Elide mode: {elide_mode}")

        if not text or width_pixels <= 0 or max_lines <= 0:
            if self.debug_mode:
                print("Invalid input, returning formatted text")
            return self.formatText(text)

        if elide_mode == 3:  # ElideNone
            return self.formatText(text)

        # QTextDocument로 실제 렌더링 크기 계산을 위한 준비
        doc = QTextDocument()
        font = QFont()
        font.setPointSizeF(font_size)
        doc.setDefaultFont(font)

        # 이진 탐색으로 최적 길이 찾기 (항상 수행)
        if self.debug_mode:
            print("Finding optimal text length...")

        plain_text = text
        left, right = 0, len(plain_text)
        best_length = 0

        # 안전 마진: "..."이 항상 표시되도록 여유 공간 확보
        safety_margin = 0.92  # 92%만 사용 (8% 여유)

        while left <= right:
            mid = (left + right) // 2

            # elide 모드에 따라 테스트 텍스트 생성
            if elide_mode == 0:  # ElideRight
                test_text = plain_text[:mid] + "..."
            elif elide_mode == 1:  # ElideLeft
                test_text = "..." + plain_text[-mid:] if mid > 0 else "..."
            elif elide_mode == 2:  # ElideMiddle
                if mid > 6:
                    half = mid // 2
                    test_text = plain_text[:half] + "..." + plain_text[-half:]
                else:
                    test_text = "..."
            else:
                test_text = plain_text[:mid]

            # 포맷팅 적용
            formatted_test = self.formatText(test_text)
            doc.setHtml(formatted_test)

            # 크기 테스트 - maxLines에 따라 다르게 비교
            if max_lines == 1:
                # 한 줄 모드: 너비로 비교 (size() 사용하여 더 정확한 측정)
                doc.setTextWidth(-1)
                test_width = doc.size().width()
                # 안전 마진 적용하여 "..."이 잘리지 않도록 함
                fits = test_width <= (width_pixels * safety_margin)
            else:
                # 여러 줄 모드: 줄 수로 비교
                doc.setTextWidth(width_pixels)
                test_line_count = doc.lineCount()
                fits = test_line_count <= max_lines

            if fits:
                best_length = mid
                left = mid + 1
            else:
                right = mid - 1

        if self.debug_mode:
            print(f"Best length found: {best_length} / {len(plain_text)}")

        # best_length가 전체 길이와 같으면 elide 없이 전체 텍스트 반환
        if best_length >= len(plain_text):
            if self.debug_mode:
                print("Text fits completely, no elide needed")
                print("=== End formatTextWithElide ===\n")
            return self.formatText(text)

        # 최적 길이로 최종 텍스트 생성
        if best_length == 0:
            return self.formatText("...")

        if elide_mode == 0:  # ElideRight
            truncate_pos = best_length
            space_pos = plain_text.rfind(' ', 0, truncate_pos)
            if space_pos > best_length * 0.8:
                truncate_pos = space_pos
            # rstrip() 제거 - 공백도 중요한 문자일 수 있음
            final_text = plain_text[:truncate_pos] + "..."

        elif elide_mode == 1:  # ElideLeft
            start_pos = len(plain_text) - best_length
            space_pos = plain_text.find(' ', start_pos, start_pos + int(best_length * 0.2))
            if space_pos != -1:
                start_pos = space_pos + 1
            # lstrip() 제거
            final_text = "..." + plain_text[start_pos:]

        elif elide_mode == 2:  # ElideMiddle
            half = best_length // 2
            front = plain_text[:half]
            back = plain_text[-half:] if half > 0 else ""

            space_pos = front.rfind(' ')
            if space_pos > half * 0.8:
                front = front[:space_pos]

            space_pos = back.find(' ')
            if space_pos != -1 and space_pos < half * 0.2:
                back = back[space_pos + 1:]

            # rstrip/lstrip 제거
            final_text = front + "..." + back
        else:
            final_text = plain_text[:best_length]

        result = self.formatText(final_text)

        if self.debug_mode:
            print(f"Final text (first 30 chars): '{final_text[:30]}'")
            print(f"Final text length: {len(final_text)}")
            print("=== End formatTextWithElide ===\n")

        return result

    def _detect_language(self, code):
        if (0xAC00 <= code <= 0xD7AF) or \
           (0x1100 <= code <= 0x11FF) or \
           (0x3130 <= code <= 0x318F):
            return 'korean'
        elif (0x3040 <= code <= 0x309F) or \
             (0x30A0 <= code <= 0x30FF):
            return 'japanese'
        elif (0x4E00 <= code <= 0x9FFF) or \
             (0x3400 <= code <= 0x4DBF):
            return 'chinese'
        else:
            return 'latin'

    def _get_font_for_language(self, lang_type):
        font_map = {
            'latin': self.latin_font,
            'korean': self.korean_font,
            'japanese': self.japanese_font,
            'chinese': self.chinese_font,
        }
        return font_map.get(lang_type, self.latin_font)

    def _escape_html(self, text):
        text = text.replace('&', '&amp;')
        text = text.replace('<', '&lt;')
        text = text.replace('>', '&gt;')
        text = text.replace('"', '&quot;')
        text = text.replace("'", '&#39;')
        return text
