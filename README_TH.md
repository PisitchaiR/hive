# Hive

> *เทอร์มินัล macOS สไตล์มินิมอลที่สร้างมาเพื่อ AI coding โดยเฉพาะ*

🇹🇭 ภาษาไทย  ·  🇬🇧 [English](README.md)

เทอร์มินัล macOS สไตล์มินิมอลที่ออกแบบมาสำหรับ AI coding โดยเฉพาะ รองรับ workspace ในแถบด้านข้าง, แบ่งหน้าจอแนวนอน/แนวตั้ง, เปิด agent ด้วยคลิกเดียว, ดูสถานะ agent แบบเรียลไทม์, และตรวจสอบสถานะ workspace พร้อมสลับ Node และ branch ได้ในคลิกเดียว โอเพนซอร์ส ลิขสิทธิ์ MIT ไม่ต้องสมัครบัญชี ไม่มีการส่งข้อมูล สถานะแอปเก็บไว้บนเครื่องทั้งหมด เรนเดอร์ด้วย GPU ผ่าน [libghostty](https://github.com/ghostty-org/ghostty)

**[ดาวน์โหลดเวอร์ชันล่าสุด](https://github.com/PisitchaiR/hive/releases/latest)**  ·  [บันทึกการเปลี่ยนแปลง](CHANGELOG.md)

---

## ฟีเจอร์

**Tab แนวตั้ง, แบ่งหน้าจอ & หลายหน้าต่าง.** Workspace ในแถบด้านข้างพับได้สามระดับ (`⌘⌃S`) แต่ละ pane มี tab strip และ tab ที่ใช้งานอยู่เป็นของตัวเอง `⌘⇧N` เปิดหน้าต่างใหม่ ลาก tab เพื่อจัดลำดับ ย้ายข้าม pane หรือวางลงในหน้าต่างอื่น — session ที่กำลังใช้งานอยู่จะย้ายไปพร้อมกันทั้งหมด ทั้ง scrollback และโปรเซสที่รันอยู่ สถานะถูกบันทึกข้ามการเปิดแอป ทุกหน้าต่างที่เปิดอยู่จะถูกคืนค่า

**เปิด AI agent ด้วยคลิกเดียว.** Claude Code · Codex · Gemini CLI · OpenCode · Amp · Cursor CLI · Copilot CLI · Grok Build · Antigravity CLI เลือกจากเมนู `+` แล้ว agent จะบูตขึ้นมาก่อน prompt แรกของคุณจะแสดง การสนทนา Claude ยังสามารถ resume ต่อได้อัตโนมัติหลังจากเปิดแอป Hive ใหม่ ปิดและเปิด tab อีกครั้งก็ได้ต่อจากที่ค้างไว้

**คลิกขวาที่ข้อความที่เลือก → "Ask <agent>".** เลือก error / บรรทัด log / path ไฟล์ แล้วคลิกขวาเลือก agent ใดก็ได้ — tab ใหม่จะเปิดขึ้นพร้อมข้อความที่เลือกถูกส่งเป็น prompt แรกแล้ว ไม่ต้อง ⌘C / ⌘V เลย ไปจาก "นี่คืออะไร" ถึงคำตอบจริงๆ ได้ทันที

**ป้อนข้อมูลได้ลื่นไหล.** คลิกที่ใดก็ได้บน zsh prompt เพื่อย้าย cursor ของ shell ไปยังตำแหน่งนั้น (ไม่ต้องกดปุ่ม modifier เช่นเดียวกับ ghostty.app) ลากไฟล์หรือโฟลเดอร์จาก Finder มาวางบน pane ใดก็ได้ เพื่อแทรก absolute path ที่ escape แล้วที่ตำแหน่ง cursor

**แสดงสถานะ agent แบบเรียลไทม์.** จุดในแถบด้านข้างติดตาม agent แต่ละตัวแบบเรียลไทม์ — กำลังทำงาน (น้ำเงิน), รอคุณ (เหลืองอำพัน), ว่าง (ไม่มีสี) จุดบน tab และ workspace จะเปลี่ยนเป็นสีแดงเมื่อคำสั่งล่าสุดออกด้วย non-zero; วางเมาส์เพื่อดู `exit N · 12.4s`

**เห็นสถานะ workspace แบบ live.** Status bar ของ pane แสดง git branch + diff (`N files +X −Y`), Python venv, Node version, และ proxy ที่ใช้งาน (`https_proxy` / `http_proxy` / `all_proxy`) อัปเดตอัตโนมัติเมื่อ Bash tool ของ agent หรือเทอร์มินัลอื่นสลับ branch คลิกที่ Node หรือ branch pill เพื่อสลับ version/branch โดยไม่ต้องพิมพ์ คลิกที่ proxy pill เพื่อดูและคัดลอก `name=value` แบบเต็ม

**SwiftUI native, ดีไซน์เรียบง่าย.** ฟอนต์ Onest + JetBrains Mono About panel แบบกำหนดเอง, เมนู native พร้อม shortcut hints, รองรับ IME เต็มรูปแบบ

**ปรับแต่งได้.** Settings (`⌘,`) ด้วยเลย์เอาต์แถบด้านข้าง: **Terminal** (ฟอนต์ / cursor / ขนาด), **Agents** (ลากเพื่อจัดลำดับ, สลับการมองเห็น, ตั้ง launch options ต่อ agent เช่น `--model opus`, เลือก default ที่ `+` และ `⌘T` เปิดโดยไม่ต้องแสดง popover, กำหนด custom agents เอง — agent ที่ใช้ Claude Code สามารถชี้ไปที่ mirror หรือ proxy พร้อม endpoint และ API key ของตัวเอง), **Advanced** (เปิด raw JSON) การปรับแต่งทั้งหมดอยู่ใน `~/.hive/settings.json` — อ่าน `~/.config/ghostty/config` ก่อน แล้วค่อย override ด้วย settings.json; การเปิดครั้งแรกจะถามว่าต้องการ import การตั้งค่า ghostty ที่มีอยู่หรือไม่

**Local โดยพื้นฐาน.** ไม่มีบัญชี, ไม่มีการส่งข้อมูล, ไม่มี cloud sync Hive เก็บสถานะของตัวเองบนเครื่องของคุณ

**ขับเคลื่อนด้วย libghostty.** เรนเดอร์เซลล์ด้วย GPU acceleration ใช้ engine เดียวกับ ghostty รวดเร็ว

## การติดตั้ง

ดาวน์โหลด `.dmg` ล่าสุดจาก [Releases](https://github.com/PisitchaiR/hive/releases) เปิดแล้วลาก `Hive.app` ไปที่ `Applications`

**การเปิดครั้งแรกจะถูก Gatekeeper บล็อก** เพราะ build ใช้ adhoc signature (ยังไม่มี Apple Developer ID — การ sign และ notarize สำหรับการแจกจ่ายสาธารณะจะมาเมื่อมีผู้ใช้จริง) คุณจะเห็น *"Hive cannot be opened because Apple cannot check it for malicious software"* หรือ *"is damaged and cannot be opened"* เลือกวิธีข้ามที่เหมาะกับคุณ:

<details>
<summary><b>วิธีที่ A — System Settings <i>(แนะนำ)</i></b></summary>

1. ดับเบิลคลิก `Hive.app` จะเห็นคำเตือน ปิดมันออกไป
2. **System Settings → Privacy & Security** เลื่อนลงไปที่ **Security**
3. คลิก **Open Anyway** ข้างๆ *"Hive was blocked to protect your Mac"* ใส่รหัสผ่าน
4. ดับเบิลคลิก `Hive.app` อีกครั้ง → คลิก **Open** เสร็จแล้ว
</details>

<details>
<summary><b>วิธีที่ B — Terminal (คำสั่งบรรทัดเดียว)</b></summary>

```sh
xattr -d com.apple.quarantine /Applications/Hive.app
```
</details>

<details>
<summary><b>วิธีที่ C — เมื่อ "Open Anyway" ไม่ปรากฏเลย</b></summary>

Sequoia บางครั้งซ่อนปุ่ม Open Anyway ทั้งหมดสำหรับ app ที่ adhoc-signed เปิดใช้งาน option "Anywhere" แบบ legacy แล้วทำวิธีที่ A ใหม่:

```sh
sudo spctl --global-disable      # macOS 15+; ระบบเก่าใช้ --master-disable
# System Settings → Privacy & Security → "Allow applications from" → Anywhere
# เปิด Hive.app → ตอนนี้จะเปิดได้แล้ว
sudo spctl --global-enable       # เปิด Gatekeeper กลับ
```

นี่คือ **การตั้งค่าระดับระบบ** ขณะปิดอยู่ เปิดกลับทันทีที่ Hive เปิดได้ครั้งแรก (whitelist ต่อแอปจะยังคงอยู่)
</details>

macOS บล็อกเฉพาะการเปิดครั้งแรก หลังจากนั้น Spotlight / Dock / Finder ทำงานตามปกติ

## Build จาก source

ต้องการ Xcode 26+ และ macOS 14+ (Sonoma — `@Observable` คือ requirement ต่ำสุด)

```sh
./scripts/setup-libghostty.sh        # ครั้งเดียว: ดึง libghostty xcframework มา
swift build
swift run                            # dev mode
swift test                           # unit tests

./scripts/build-app.sh               # สร้าง dist/Hive.app
./scripts/build-dmg.sh --build       # สร้าง dist/Hive-vX.Y.Z.dmg
```

`Vendor/` และ `dist/` อยู่ใน gitignore สคริปต์ setup ของ libghostty เป็น idempotent

## ลิขสิทธิ์

MIT — ดูที่ [LICENSE](LICENSE) ทรัพย์สินของบุคคลที่สามที่รวมอยู่ด้วยยังคงใช้ลิขสิทธิ์ต้นทาง ดูที่ [NOTICE.md](NOTICE.md)
