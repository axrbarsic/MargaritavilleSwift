// Экран тележки уборщицы: голосовая заметка, расходники, фото и видео.
// Открывается долгим нажатием на имя уборщицы. Источник: Features/CartDetails/CartDetailsScreen.swift.
import { h } from "./dom.js";
import { backButton, panel, pushScreen, updatedLabel } from "./screen-stack.js";
import { mediaActions, mediaGrid, openMediaViewer } from "./media-views.js";
import { voiceBubble, voicePanel } from "./voice-panel.js";
import { consumablesSection } from "./consumables-view.js";
import { deleteAttachment, saveAttachment } from "../infra/media-files.js";
import { tr } from "../i18n/i18n.js";

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

    const voice = voicePanel(tr("Голосовая заметка"), feedback, async ({ blob, transcript }) => {
      try {
        // Без аудио (режим «только текст») сохраняется одна расшифровка.
        if (blob) {
          const attachment = await saveAttachment("audio", blob, transcript);
          store.addCartMedia(cartID, attachment);
        }
        // Без аудио текст дописывается к заметке тележки, а не заменяет её.
        if (transcript) store.updateCartNote(cartID, blob ? transcript : [store.cart(cartID)?.note, transcript].filter(Boolean).join("\n"));
        showError(null);
      } catch (e) {
        showError(e?.message || tr("Не удалось сохранить голос"));
      }
    });

    const refresh = () => {
      const c = cart();
      if (!c) return close();
      stamp.hidden = c.noteUpdatedAt == null;
      stamp.textContent = c.noteUpdatedAt == null ? "" : tr("Обновлено: {time}", { time: updatedLabel(c.noteUpdatedAt) });
      voiceList.replaceChildren(...(voices().length
        ? voices().map((a) => voiceBubble(a, () => remove(a)))
        : [h("p", { class: "detail-hint dim" }, tr("Голосовые заметки по тележке появятся здесь пузырями после записи."))]));
      mediaBox.replaceChildren(visual().length
        ? mediaGrid(visual(), { onOpen: (a) => openMediaViewer(visual(), a), onDelete: remove })
        : h("p", { class: "detail-hint" }, tr("Фото и видео сохраняются только локально на устройстве.")));
      consumables.refresh();
    };
    setRefresh(refresh);
    refresh();

    return h("main", { class: "detail-screen" },
      h("header", { class: "detail-header" },
        backButton(() => { voice.cancel(); close(); }),
        h("div", { class: "detail-heading" },
          h("div", { class: "detail-cart-title" }, title ?? tr("Тележка {cart}", { cart: cartID })),
          subtitle ? h("div", { class: "detail-cart-subtitle" }, subtitle) : null,
          stamp
        )
      ),
      h("div", { class: "detail-scroll" },
        panel(tr("Заметка"), voice.element, voiceList),
        panel(tr("Расходники"), consumables.element),
        panel(tr("Медиа"), mediaActions(feedback, (a) => { store.addCartMedia(cartID, a); showError(null); }, showError), error, mediaBox)
      )
    );
  });
}
