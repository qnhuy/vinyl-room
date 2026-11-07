require("dotenv").config();
const { GoogleGenAI } = require("@google/genai");

let ai = null;
if (process.env.GEMINI_API_KEY) {
  ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
}

/**
 * Service AI phân tích tâm trạng & gợi ý bài hát kế tiếp phù hợp nhất (Smart Flow).
 *
 * @param {Object} currentSong Bài hát đang phát
 * @param {Array} candidateSongs Danh sách bài hát ứng viên trong kho nhạc
 * @returns {Promise<{ selectedSong: Object, reason: string, mood: string }>}
 */
async function getSmartNextSong({ currentSong, candidateSongs }) {
  if (!candidateSongs || candidateSongs.length === 0) {
    return null;
  }

  // Nếu chỉ có 1 bài ứng viên, chọn luôn bài đó
  if (candidateSongs.length === 1) {
    return {
      selectedSong: candidateSongs[0],
      mood: candidateSongs[0].genre_name || "Tương đồng",
      reason: "Giai điệu tiếp nối tâm trạng hiện tại",
    };
  }

  // Chuẩn bị danh sách ứng viên rút gọn gửi cho AI
  const candidatesText = candidateSongs
    .map(
      (s) =>
        `- ID: ${s.music_id} | Bài: "${s.music_name}" | Ca sĩ: ${s.artist_name || "Không rõ"} | Thể loại: ${s.genre_name || "Nhạc trẻ"}`
    )
    .join("\n");

  const prompt = `Bạn là một DJ và chuyên gia âm nhạc thông minh của ứng dụng Vinyl Room.
Người dùng đang nghe bài hát sau:
- Tên: "${currentSong.music_name}"
- Ca sĩ: ${currentSong.artist_name || "Chưa rõ"}
- Thể loại: ${currentSong.genre_name || "Nhạc trẻ"}

Nhiệm vụ của bạn:
1. Phân tích phong cách, giai điệu và tâm trạng (mood) của bài hát hiện tại.
2. Chọn ra DUY NHẤT 1 bài hát trong danh sách ứng viên dưới đây có tâm trạng và giai điệu tiếp nối mượt mà nhất để người nghe không bị tụt cảm xúc hay ngắt quãng tâm trạng.
3. Không chọn bài có phong cách đối lập quá gắt (ví dụ đang nghe Ballad nhẹ nhàng thì không nhảy sang Rock/Dance sôi động).

Danh sách bài hát ứng viên:
${candidatesText}

Hãy trả về duy nhất định dạng JSON theo mẫu sau:
{
  "music_id": <số nguyên là ID của bài hát được chọn>,
  "mood": "<tâm trạng tương đồng, dưới 6 từ, ví dụ: 'Ballad sâu lắng' hoặc 'Indie chill thư giãn'>",
  "reason": "<lý do ngắn gọn bằng tiếng Việt dưới 15 từ, ví dụ: 'Cùng giai điệu acoustic mộc mạc, êm dịu'>"
}`;

  try {
    if (!ai) {
      throw new Error("Chưa cấu hình GEMINI_API_KEY");
    }

    const response = await ai.models.generateContent({
      model: "gemini-3.8-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
      },
    });

    const parsed = JSON.parse(response.text);
    const chosenSong = candidateSongs.find(
      (s) => Number(s.music_id) === Number(parsed.music_id)
    );

    if (chosenSong) {
      return {
        selectedSong: chosenSong,
        mood: parsed.mood || chosenSong.genre_name || "Tâm trạng tương đồng",
        reason: parsed.reason || "Cùng phong cách và giai điệu mượt mà",
      };
    }
  } catch (err) {
    console.error("[AiService Warning]: Gọi Gemini AI thất bại, chuyển sang thuật toán dự phòng:", err.message);
  }

  // Thuật toán dự phòng (Fallback): ưu tiên cùng thể loại genre_id hoặc artist_id
  const sameGenre = candidateSongs.find(
    (s) => s.genre_id && s.genre_id === currentSong.genre_id
  );
  const fallbackSong = sameGenre || candidateSongs[0];

  return {
    selectedSong: fallbackSong,
    mood: fallbackSong.genre_name || "Tương đồng",
    reason: sameGenre
      ? `Cùng thể loại ${fallbackSong.genre_name || "âm nhạc"} phù hợp`
      : "Giai điệu tiếp nối tâm trạng của bạn",
  };
}

module.exports = {
  getSmartNextSong,
};
