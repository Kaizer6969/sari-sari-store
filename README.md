# 🏪 Sari-Sari Store (Pixel Art Simulator)

Isang authentic Pinoy Pixel Art Sari-Sari Store simulator na ginawa gamit ang **Flutter** para sa **Android & iOS**.

---

## 🎮 Mga Game Mechanics na Nakapaloob:

1. **🏬 Tindahan Simulator & Pagbebenta**
   - Ikaw ang tindero/tindera sa sari-sari store.
   - May mga customer na bibisita (Aling Marites, Mang Boy, Bongbong na bata, Tinay na estudyante, atbp.) na may dalang sariling order at emoji avatar.
   - May visual canvas ng tindahan na may yero, kahoy, rehas, nakasabit na sachets ng kape at shampoo, chichirya racks, garapon ng kendi, at sako ng bigas.

2. **💵 Sukli Mechanics (Paghahanda ng Barya at Bills)**
   - Kapag nag-abot ng pera ang customer, lalabas ang interactive dialog kung saan kailangan mong piliin ang tamang sukli gamit ang mga denominations:
     - **Bills:** ₱500, ₱200, ₱100, ₱50, ₱20
     - **Barya (Coins):** ₱10, ₱5, ₱1
   - Kung kulang o sobra ang sukli, magrereklamo ang customer! Kapag tama ang sukli, magpapasalamat sila at papasok ang benta.

3. **📱 GCash Scammer System**
   - May mga bogus o scammer na customers na magpapakita ng smartphone screen na may pekeng GCash receipt.
   - Makikita mo ang mga detalye sa kunwaring phone screen:
     - **Scammer indicators:** Pending / Processing status, maling halaga (halimbawa ₱15 imbes na ₱150), sketchy reference number ("DRAFT-992341").
     - **Legit payments:** "Payment Successful", green checkmark, tugmang halaga.
   - Ikaw ang magpapasya kung tatanggapin o tatanggihan:
     - Kapag tinanggap mo ang scammer: **Na-scam ka!** Mawawalan ka ng paninda nang walang natanggap na pera, at bababa ang reputasyon mo.
     - Kapag nahuli/tinanggihan mo: Tatakbo ang scammer at tataas ang reputasyon ng tindahan mo!

4. **🗺️ Interactive Barangay Mapa (Supermarket & Barangay Hall)**
   - Buksan ang **MAPA** sa ibaba upang makapunta sa:
     - **🛒 Supermarket (Pamilihan ng Paninda):** Bilihan ng wholesale stock gamit ang iyong puhunan.
     - **🏛️ Barangay Hall:** Kausapin si Kapitan Roger para kumuha ng Opisyal na **Barangay Business Permit (₱200)**.
   - May travel time sa bawat paglalakbay na sumusulong sa oras ng laro.

5. **📜 Barangay Business Permit**
   - Sa simula, may mga panindang bawal ibenta nang walang permit (tulad ng Yosi / sigarilyo).
   - Sa Barangay Hall, magbayad ng ₱200 kay Kapitan para makakuha ng lisensya na magbubukas ng lahat ng paninda sa Supermarket at magpapataas ng reputasyon!

6. **⏰ Araw at Gabi Cycle (6:00 AM Start)**
   - Nagsisimula ang Day 1 ng **6:00 AM** na may konting panimulang stock (5 piraso ng bawat basic item tulad ng kape, shampoo, sabon, bigas, itlog, de lata, softdrinks, kendi, chichirya, tubig, noodles).
   - **Customer Frequency:** 
     - **6:00 AM - 9:00 AM (Umaga):** Pinakamaraming bumibili (morning rush).
     - **10:00 AM - 3:00 PM (Tanghali):** Katamtamang dami ng tao.
     - **Gabi:** Pa-unti nang pa-unti ang customer, ngunit mas mataas ang tsansa ng mga scammer!
   - May nakabiting bumbilya sa tindahan na umiilaw tuwing sasapit ang dilim.
   - May opsyon na **🌙 TULOG** para magpahinga at sumulong sa susunod na araw (magigising muli ng 6:00 AM).

7. **🛑 Overhead Bukas / Sarado Signage**
   - May malaking signage sa itaas ng tindahan.
   - Pindutin lamang ito para magpalit mula **BUKAS (OPEN)** papuntang **SARADO (CLOSED)**.
   - Kapag Sarado ang tindahan: **Walang customer na pupunta**, para makapagpahinga ka, makapag-inventory, o makabiyahe sa Supermarket.

8. **💾 Local Storage (Phone Save Progress)**
   - Awtomatikong nagse-save ang progreso gamit ang `SharedPreferences` ng telepono.
   - Naka-save ang pera, araw, oras, reputasyon, stock, permit status, at mga nahuling scammer.
   - May "Ituloy ang Tindahan" button sa Title Screen.

---

## 🚀 Paano I-run sa Android & iOS:

```bash
# 1. Pumunta sa folder
cd c:\gamedev\sari_sari_store

# 2. I-download ang dependencies
flutter pub get

# 3. I-run sa konektadong Android phone o iOS simulator
flutter run
```
