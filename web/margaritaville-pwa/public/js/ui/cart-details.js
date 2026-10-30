// Экран тележки уборщицы: голосовая заметка, расходники, фото и видео.
// Открывается долгим нажатием на имя уборщицы. Источник: Features/CartDetails/CartDetailsScreen.swift.
import { h } from "./dom.js";
import { backButton, panel, pushScreen, updatedLabel } from "./screen-stack.js";
import { mediaActions, mediaGrid, openMediaViewer } from "./media-views.js";
import { voiceBubble, voicePanel } from "./voice-panel.js";
import { consumablesSection } from "./consumables-view.js";
import { deleteAttachment, saveAttachment } from "../infra/media-files.js";

export function openCartDetails(app, cartID, title, subtitle) {
  const { store, feedback } = app;
  return pushScreen((close, setRefresh) => {
    const cart = () => store.cart(cartID);
    const stamp = h("div", { class: "detail-substamp" });
    const error = h("div", { class: "detail-error", hidden: true });
    const voiceList = h("div", { class: "voice-list" });
    const mediaBox = h("div", { class: "media-box" });
    const showError = (message) => { error.hidden = !message; error.textContent = message ?? ""; };
    const attachments = () => cart()?.mediaAttachments ?? [];
    const visual = () => attachments().filter((a) => a.kind === "photo" || a.kind === "video");
    const voices = () => attachments().filter((a) => a.kind === "audio");
    const consumables = consumablesSection(store, cartID, feedback);

    const remove = async (attachment) => {
      await deleteAttachment(attachment);
      store.removeCartMedia(cartID, attachment);
    };

    const voice = voicePanel("Голосовая заметка", feedback, async ({ blob, transcript }) => {
      try {
        const attachment = await saveAttachment("audio", blob, transcript);
        store.addCartMedia(cartID, attachment);
        if (transcript) store.updateCartNote(cartID, transcript);
        showError(null);
      } catch (e) {
        showError(e?.message || "Не удалось сохранить голос");
      }
    });

    const refresh = () => {
      const c = cart();
      if (!c) return close();
      stamp.hidden = c.noteUpdatedAt == null;
      stamp.textContent = c.noteUpdatedAt == null ? "" : `Обновлено: ${updatedLabel(c.noteUpdatedAt)}`;
      voiceList.replaceChildren(...(voices().length
        ? voices().map((a) => voiceBubble(a, () => remove(a)))
        : [h("p", { class: "detail-hint dim" }, "Голосовые заметки по тележке появятся здесь пузырями после записи.")]));
      mediaBox.replaceChildren(visual().length
        ? mediaGrid(visual(), { onOpen: (a) => openMediaViewer(visual(), a), onDelete: remove })
        : h("p", { class: "detail-hint" }, "Фото и видео сохраняются только локально на устройстве."));
      consumables.refresh();
    };
    setRefresh(refresh);
    refresh();

    return h("main", { class: "detail-screen" },
      h("header", { class: "detail-header" },
        backButton(() => { voice.cancel(); close(); }),
        h("div", { class: "detail-heading" },
          h("div", { class: "detail-cart-title" }, title ?? `Тележка ${cartID}`),
          subtitle ? h("div", { class: "detail-cart-subtitle" }, subtitle) : null,
          stamp
        )
      ),
      h("div", { class: "detail-scroll" },
        panel("Заметка", voice.element, voiceList),
        panel("Расходники", consumables.element),
        panel("Медиа", mediaActions(feedback, (a) => { store.addCartMedia(cartID, a); showError(null); }, showError), error, mediaBox)
      )
    );
  });
}
