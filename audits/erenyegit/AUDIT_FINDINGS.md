# Audit Findings – CavalRe Contracts

Kısa özet: Repoda gözden kaçmış olabilecek hatalar ve tutarsızlıklar. PR/issue olarak sunulabilir.

---

## 1. **Kritik: Router’a gönderilen ETH kullanılamıyor / DoS**

**Dosya:** `modules/Router.sol` (receive), hiçbir modülde `handleNative` yok.

**Durum:**  
`receive()` → `INativeHandler(address(this)).handleNative{value: msg.value}()`.  
Bu selector’ı kaydeden modül yok; Router’da fallback `modules[selector] == 0` → **CommandNotFound** revert.

**Sonuç:** Router adresine doğrudan ETH gönderen her çağrı revert olur. ETH kabul edilmesi bekleniyorsa bu bir bug; değilse en azından dokümantasyon/comment ile netleştirilmeli.

**Öneri:**  
- Ya Ledger (veya başka bir modül) `handleNative()` implement edip Router’a register etmeli,  
- Ya da `receive()` kaldırılıp / devre dışı bırakılıp “ETH kabul edilmez” davranışı açıkça belgelenmeli.

---

## 2. **Yüksek: ILedger.addSubAccount parametre adı yanlış (isInternal vs isCredit)** ✅ Düzeltildi

**Dosya:** `interfaces/ILedger.sol` satır 61.

**Durum:**  
- Arayüz: `addSubAccount(..., bool isInternal)`  
- Gerçek davranış (Ledger.sol, LedgerLib): parametre **isCredit** (hesabın credit/debit tarafı).  
- Tüm testler ve kullanım `true`/`false` ile credit tarafını geçiriyor (örn. Source hesabı için `true`).

**Düzeltme:** ILedger’da parametre adı `isCredit` yapıldı ve NatSpec eklendi.

---

## 3. **Orta: subAccountIndex 1-based, subAccount 0-based – API tutarsızlığı**

**Dosya:** `libraries/LedgerLib.sol`.

**Durum:**  
- `subIndex[_sub]` eklerken `s.subs[parent_].length` atanıyor → **1-based** index (1, 2, 3, …).  
- `subAccount(parent_, index_)` → `store().subs[parent_][index_]` → **0-based** array index.  
- Remove fonksiyonları yorumda “1-based” diyor ve `_index - 1` ile erişiyor; tutarlı.

**Sonuç:**  
`subAccount(parent_, subAccountIndex(parent_, addr))` kullanılırsa off-by-one (yanlış hesap veya out-of-bounds).  
`subAccount` şu an sadece internal; public API `subAccounts()` ve `subAccountIndex()`. Yine de ileride biri library’i kullanıp bu ikisini birlikte kullanırsa hata riski var.

**Öneri:**  
- Ya `subAccountIndex` 0-based dönecek şekilde değiştirilir (`uint32(s.subs[parent_].length - 1)` ve remove’da buna göre güncelleme),  
- Ya da dokümantasyona “subAccountIndex 1-based, subAccount 0-based; birlikte kullanırken index - 1 gerekir” notu eklenir.

---

## 4. **Düşük: ERC20Wrapper.mint / burn sadece event, bakiye değişmiyor**

**Dosya:** `modules/Ledger.sol` (ERC20Wrapper) satır 156–162.

**Durum:**  
`mint(to_, amount_)` ve `burn(from_, amount_)` sadece `Transfer` emit ediyor; Ledger state’ine dokunmuyor. Asıl bakiye değişimi TestLedger’daki `mint(toParent_, to_, amount_)` gibi fonksiyonlarda: önce `LedgerLib.credit`/transfer, sonra wrapper’da `mint`/`burn` ile event.

**Sonuç:**  
Doğru kullanımda sorun yok. Ama birisi sadece `wrapper.mint(to, amount)` çağırırsa bakiye artmaz, sadece event yanıltıcı olur. Wrapper `routerOnly` olduğu için sadece Router (Ledger) çağırabilir – tasarım buna dayanıyor.

**Öneri:**  
Natspec’te “Only emits Transfer; actual balance change must be performed by Ledger (e.g. credit/transfer) before calling this” gibi bir uyarı eklenebilir.

---

## 5. **Düşük: addExternalToken – IERC20Metadata reentrancy**

**Dosya:** `libraries/LedgerLib.sol` – `addExternalToken(token_)`.

**Durum:**  
`IERC20Metadata(token_).name()`, `symbol()`, `decimals()` çağrılıyor. Kötü niyetli bir token bu çağrılarda reentrancy yapabilir.

**Sonuç:**  
Sadece owner bu fonksiyonu çağırabiliyor; fonksiyon state’i güncelledikten sonra external call yapmıyor, önce metadata alınıyor. Yine de owner’ı tuzaklayan bir token (örn. callback’te başka bir işlem tetikleyen) teorik risk.

**Öneri:**  
External token’ı whitelist’e eklemeden önce basit bir “malicious token” testi veya dokümantasyonda “Only add trusted tokens” uyarısı.

---

## Özet tablo

| # | Önem   | Konu                              | Dosya / Yer              |
|---|--------|------------------------------------|---------------------------|
| 1 | Kritik | Router’a ETH gönderilince revert  | Router.sol, handleNative  |
| 2 | Yüksek | ILedger addSubAccount isInternal  | ILedger.sol:61            |
| 3 | Orta   | subAccountIndex vs subAccount API | LedgerLib.sol             |
| 4 | Düşük  | Wrapper mint/burn sadece event    | Ledger.sol ERC20Wrapper   |
| 5 | Düşük  | addExternalToken reentrancy       | LedgerLib.sol             |

En çok “gözüne girecek” olanlar: **1 (ETH DoS)** ve **2 (interface semantik hatası)**.  
İstersen bir sonraki adımda 1 ve 2 için doğrudan patch (veya PR açıklaması) metni de çıkarabilirim.

